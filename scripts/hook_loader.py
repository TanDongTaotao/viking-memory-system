#!/usr/bin/env python3
"""
OpenClaw Agent Hooks Manager
管理 OpenClaw 会话生命周期中的钩子脚本执行
"""

import os
import subprocess
import logging
import signal
import time
from pathlib import Path
from typing import List, Dict, Any, Optional

import yaml

# 配置常量
DEFAULT_CONFIG_PATH = Path.home() / ".openclaw" / "config" / "agent-hooks.yaml"
ENV_CONFIG_PATH = os.environ.get("OPENCLAW_AGENT_HOOKS_CONFIG")
LOG_FILE = Path.home() / ".openclaw" / "logs" / "hooks.log"
MAX_STDOUT_SIZE = 2048  # 2KB 限制
DEFAULT_TIMEOUT = 30

# 设置日志
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=str(LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("HooksManager")


class HookConfig:
    """钩子配置"""
    def __init__(self, name: str, script: str, timeout: int = DEFAULT_TIMEOUT,
                 enabled: bool = True, env: Optional[Dict[str, str]] = None,
                 args: Optional[List[str]] = None):
        self.name = name
        self.script = script
        self.timeout = timeout
        self.enabled = enabled
        self.env = env or {}
        self.args = args or []

    @classmethod
    def from_dict(cls, name: str, data: Dict) -> 'HookConfig':
        return cls(
            name=name,
            script=data.get('script', ''),
            timeout=data.get('timeout', DEFAULT_TIMEOUT),
            enabled=data.get('enabled', True),
            env=data.get('env', {}),
            args=data.get('args', [])
        )


class HooksManager:
    """管理 OpenClaw 钩子的生命周期与执行。"""

    def __init__(self, config_path: Optional[str] = None):
        # 优先级: 传入路径 > 环境变量 > 默认路径
        if config_path:
            self.config_path = Path(config_path)
        elif ENV_CONFIG_PATH:
            self.config_path = Path(ENV_CONFIG_PATH)
        else:
            self.config_path = DEFAULT_CONFIG_PATH

        self.hooks: Dict[str, List[HookConfig]] = {}
        self._load_config()

    def _load_config(self) -> None:
        """加载并解析 YAML 配置文件。"""
        if not self.config_path.exists():
            logger.warning(f"配置文件未找到: {self.config_path}，将不运行任何钩子。")
            return

        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                config = yaml.safe_load(f) or {}
                hooks_data = config.get("hooks", {})

                for hook_type, hooks_list in hooks_data.items():
                    self.hooks[hook_type] = []
                    for hook_data in hooks_list:
                        name = hook_data.get("name", "unnamed")
                        self.hooks[hook_type].append(HookConfig.from_dict(name, hook_data))

                logger.info(f"已加载 {len(self.hooks)} 种钩子类型")
        except Exception as e:
            logger.error(f"解析配置文件失败: {e}")

    def _execute_hook(self, hook: HookConfig, agent_name: str = "",
                      session_id: str = "", message: str = "") -> Optional[str]:
        """执行单个钩子，处理超时、环境和输出捕获。"""
        if not hook.enabled:
            return None

        if not hook.script:
            logger.error(f"钩子 '{hook.name}' 缺少 script 路径。")
            return None

        # 扩展 ~ 为用户家目录
        script_path = os.path.expanduser(hook.script)

        # 构建环境变量
        env = os.environ.copy()
        env.update({
            "OPENCLAW_AGENT_NAME": agent_name,
            "OPENCLAW_SESSION_ID": session_id,
            "OPENCLAW_HOOK_TYPE": hook.name,
        })
        env.update(hook.env)

        # 构建命令
        full_cmd = [script_path] + hook.args
        logger.info(f"执行钩子 [{hook.name}]: {' '.join(full_cmd)}")

        try:
            # 使用 os.setsid 创建进程组，确保超时能清理子进程
            process = subprocess.Popen(
                full_cmd,
                stdin=subprocess.PIPE if message else subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
                text=True,
                preexec_fn=os.setsid
            )

            try:
                # 消息通过 stdin 传递
                stdout, stderr = process.communicate(
                    input=message if message else None,
                    timeout=hook.timeout
                )
            except subprocess.TimeoutExpired:
                logger.warning(f"钩子执行超时 ({hook.timeout}s): {hook.name}。正在终止...")

                try:
                    # 先尝试 SIGTERM
                    os.killpg(os.getpgid(process.pid), signal.SIGTERM)
                    time.sleep(1)
                    if process.poll() is None:
                        # 仍未停止则 SIGKILL
                        os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                except ProcessLookupError:
                    pass

                stdout, stderr = process.communicate()
                logger.error(f"钩子 '{hook.name}' 因超时被强制终止。")

            if stderr:
                logger.warning(f"钩子 '{hook.name}' stderr: {stderr.strip()}")

            if process.returncode != 0:
                logger.warning(f"钩子 '{hook.name}' 失败，退出码: {process.returncode}")
                # 继续执行其他钩子

            # 截断 stdout 至 2KB
            if stdout:
                stdout_bytes = stdout.encode('utf-8')
                if len(stdout_bytes) > MAX_STDOUT_SIZE:
                    logger.info(f"钩子 '{hook.name}' 输出超过 2KB，执行截断。")
                    stdout = stdout_bytes[:MAX_STDOUT_SIZE].decode('utf-8', errors='ignore')

                return stdout.strip()

            return None

        except Exception as e:
            logger.error(f"执行钩子 '{hook.name}' 时出错: {e}")
            return None

    def run_session_start_hooks(self, agent_name: str = "",
                                  session_id: str = "") -> List[str]:
        """执行会话开始钩子"""
        return self._run_hooks("on_session_start", agent_name, session_id)

    def run_session_end_hooks(self, agent_name: str = "",
                               session_id: str = "") -> List[str]:
        """执行会话结束钩子"""
        return self._run_hooks("on_session_end", agent_name, session_id)

    def run_message_hooks(self, agent_name: str = "",
                          session_id: str = "",
                          message: str = "") -> List[str]:
        """执行消息钩子"""
        return self._run_hooks("on_message", agent_name, session_id, message)

    def _run_hooks(self, hook_type: str, agent_name: str = "",
                   session_id: str = "", message: str = "") -> List[str]:
        """触发特定类型的钩子并收集注入上下文。"""
        if hook_type not in self.hooks:
            logger.debug(f"未定义钩子类型: {hook_type}")
            return []

        results = []
        for hook in self.hooks[hook_type]:
            output = self._execute_hook(hook, agent_name, session_id, message)
            if output:
                results.append(output)

        return results


def main():
    """命令行入口"""
    import sys

    if len(sys.argv) < 2:
        print("Usage: hook_loader.py <hook_type> [agent_name] [session_id] [message]")
        print("  hook_type: on_session_start | on_session_end | on_message")
        sys.exit(1)

    hook_type = sys.argv[1]
    agent_name = sys.argv[2] if len(sys.argv) > 2 else ""
    session_id = sys.argv[3] if len(sys.argv) > 3 else ""
    message = sys.argv[4] if len(sys.argv) > 4 else ""

    manager = HooksManager()

    if hook_type == "on_session_start":
        outputs = manager.run_session_start_hooks(agent_name, session_id)
    elif hook_type == "on_session_end":
        outputs = manager.run_session_end_hooks(agent_name, session_id)
    elif hook_type == "on_message":
        outputs = manager.run_message_hooks(agent_name, session_id, message)
    else:
        print(f"未知钩子类型: {hook_type}")
        sys.exit(1)

    for idx, out in enumerate(outputs):
        print(f"<hook_context type='{hook_type}' index='{idx}'>\n{out}\n</hook_context>")


if __name__ == "__main__":
    main()
