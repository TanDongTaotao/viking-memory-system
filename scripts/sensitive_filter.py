#!/usr/bin/env python3
"""
敏感信息过滤器 (Sensitive Content Filter)
用于社区发布前的敏感信息检测和过滤

支持检测:
- API Key: sk-xxx, api_key=xxx, API_KEY
- Token: Bearer xxx, token=xxx, TOKEN
- 密码: password=xxx, pwd=xxx, PASSWD
- IP 地址、端口号
- 邮箱地址、电话号码
- 身份证号等个人隐私
"""

import re
import json
import os
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict
from datetime import datetime

# 敏感信息模式配置
SENSITIVE_PATTERNS = {
    # API Key 格式
    "api_key": [
        r'sk-[a-zA-Z0-9]{20,}',  # OpenAI API Key 格式
        r'api_key\s*[=:]\s*[\w-]{16,}',
        r'API_KEY\s*[=:]\s*[\w-]{16,}',
        r'apikey\s*[=:]\s*[\w-]{16,}',
    ],
    # Token 格式
    "token": [
        r'Bearer\s+[a-zA-Z0-9_-]{20,}',
        r'token\s*[=:]\s*[\w-]{20,}',
        r'TOKEN\s*[=:]\s*[\w-]{20,}',
        r'access_token\s*[=:]\s*[\w-]{20,}',
    ],
    # 密码格式 (匹配到第一个空白或特殊字符)
    "password": [
        r'(?:password|pwd|passwd|secret)\s*[=:]\s*[^\s,，;；\n]{4,20}',
    ],
    # IP 地址
    "ip_address": [
        r'(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)',
    ],
    # 端口号 (常见服务端口)
    "port": [
        r':\d{2,5}\b(?!\d)',  # 排除常见数字后缀
    ],
    # 邮箱地址
    "email": [
        r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
    ],
    # 电话号码 (中国手机号 - 更精确匹配)
    "phone": [
        r'\b1[3-9]\d{9}\b',  # 中国手机号，带单词边界
    ],
    # 身份证号 (中国) - 更宽松的匹配
    "id_card": [
        r'(?:身份证[:：]?\s*)?[1-9]\d{5}(?:19|20)\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}[\dXx]',
    ],
    # 电话号码 (中国手机号)
    "phone": [
        r'(?:手机[号：:]\s*)?1[3-9]\d{9}',  # 带关键词的手机号
    ],
    # 银行卡号
    "bank_card": [
        r'\b\d{16,19}\b',
    ],
    # AWS 密钥
    "aws_key": [
        r'(?:AKIA|ABIA|ACCA|ASIA)[A-Z0-9]{16}',
    ],
    # GitHub Token
    "github_token": [
        r'gh[pousr]_[A-Za-z0-9_]{36,}',
    ],
    # 私钥格式
    "private_key": [
        r'-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----',
    ],
}

# 配置文件路径
CONFIG_DIR = os.path.expanduser("~/.openclaw")
WHITELIST_FILE = os.path.join(CONFIG_DIR, "sensitive_filter_whitelist.txt")
BLACKLIST_FILE = os.path.join(CONFIG_DIR, "sensitive_filter_blacklist.txt")


@dataclass
class SensitiveMatch:
    """敏感信息匹配结果"""
    type: str
    value: str
    start: int
    end: int
    masked_value: str


@dataclass
class FilterResult:
    """过滤结果"""
    passed: bool
    risk_level: str  # "low", "medium", "high", "critical"
    matches: List[SensitiveMatch]
    filtered_text: str
    need_review: bool
    
    def to_dict(self) -> dict:
        return {
            "passed": self.passed,
            "risk_level": self.risk_level,
            "matches": [asdict(m) for m in self.matches],
            "filtered_text": self.filtered_text,
            "need_review": self.need_review
        }


class SensitiveFilter:
    """敏感信息过滤器"""
    
    def __init__(self, whitelist: Optional[List[str]] = None, blacklist: Optional[List[str]] = None):
        self.whitelist = whitelist or self._load_whitelist()
        self.blacklist = blacklist or self._load_blacklist()
        self.compiled_patterns = self._compile_patterns()
    
    def _load_whitelist(self) -> List[str]:
        """加载白名单"""
        if os.path.exists(WHITELIST_FILE):
            with open(WHITELIST_FILE, 'r', encoding='utf-8') as f:
                return [line.strip() for line in f if line.strip() and not line.startswith('#')]
        return []
    
    def _load_blacklist(self) -> List[str]:
        """加载黑名单"""
        if os.path.exists(BLACKLIST_FILE):
            with open(BLACKLIST_FILE, 'r', encoding='utf-8') as f:
                return [line.strip() for line in f if line.strip() and not line.startswith('#')]
        return []
    
    def _compile_patterns(self) -> Dict[str, List[re.Pattern]]:
        """编译所有正则表达式"""
        compiled = {}
        for category, patterns in SENSITIVE_PATTERNS.items():
            compiled[category] = [re.compile(p, re.IGNORECASE) for p in patterns]
        return compiled
    
    def _mask_value(self, value: str, category: str) -> str:
        """遮蔽敏感值"""
        if len(value) <= 4:
            return "*" * len(value)
        
        # 根据类型决定遮蔽方式
        if category in ("password", "token", "api_key", "private_key"):
            return value[:2] + "*" * (len(value) - 4) + value[-2:]
        elif category in ("email", "phone", "id_card", "bank_card"):
            return value[:3] + "*" * (len(value) - 6) + value[-3:]
        else:
            return value[:2] + "*" * (len(value) - 2)
    
    def _is_whitelisted(self, value: str) -> bool:
        """检查是否在白名单中"""
        for white_item in self.whitelist:
            if white_item.lower() in value.lower():
                return True
        return False
    
    def _is_blacklisted(self, value: str) -> bool:
        """检查是否在黑名单中"""
        for black_item in self.blacklist:
            if black_item.lower() in value.lower():
                return True
        return False
    
    def filter_content(self, text: str) -> FilterResult:
        """
        过滤内容中的敏感信息
        
        Args:
            text: 待过滤的文本
            
        Returns:
            FilterResult: 过滤结果
        """
        matches: List[SensitiveMatch] = []
        filtered_text = text
        
        # 遍历所有模式
        for category, patterns in self.compiled_patterns.items():
            for pattern in patterns:
                for match in pattern.finditer(text):
                    value = match.group()
                    
                    # 跳过白名单中的内容
                    if self._is_whitelisted(value):
                        continue
                    
                    # 跳过黑名单中的内容（但记录）
                    if self._is_blacklisted(value):
                        matches.append(SensitiveMatch(
                            type=category,
                            value=value,
                            start=match.start(),
                            end=match.end(),
                            masked_value=self._mask_value(value, category)
                        ))
                        continue
                    
                    # 记录匹配
                    masked = self._mask_value(value, category)
                    matches.append(SensitiveMatch(
                        type=category,
                        value=value,
                        start=match.start(),
                        end=match.end(),
                        masked_value=masked
                    ))
        
        # 去重
        unique_matches = []
        seen = set()
        for m in matches:
            key = (m.type, m.start, m.end)
            if key not in seen:
                seen.add(key)
                unique_matches.append(m)
        
        # 生成过滤后的文本
        filtered_text = text
        # 按位置逆序替换，避免索引偏移
        for m in sorted(unique_matches, key=lambda x: x.start, reverse=True):
            filtered_text = filtered_text[:m.start] + m.masked_value + filtered_text[m.end:]
        
        # 计算风险等级
        risk_level = self._calculate_risk_level(unique_matches)
        
        # 判断是否需要人工确认
        need_review = risk_level in ("high", "critical") or len(unique_matches) > 5
        
        return FilterResult(
            passed=risk_level == "low" and len(unique_matches) == 0,
            risk_level=risk_level,
            matches=unique_matches,
            filtered_text=filtered_text,
            need_review=need_review
        )
    
    def _calculate_risk_level(self, matches: List[SensitiveMatch]) -> str:
        """计算风险等级"""
        if not matches:
            return "low"
        
        # 高风险类型
        high_risk_types = {"private_key", "aws_key", "github_token", "api_key", "token", "password"}
        # 中风险类型
        medium_risk_types = {"id_card", "bank_card"}
        
        has_high_risk = any(m.type in high_risk_types for m in matches)
        has_medium_risk = any(m.type in medium_risk_types for m in matches)
        
        if has_high_risk:
            return "critical"
        elif has_medium_risk:
            return "high"
        elif len(matches) > 3:
            return "medium"
        else:
            return "low"


def filter_content(text: str, whitelist: Optional[List[str]] = None) -> dict:
    """
    便捷函数：过滤敏感信息
    
    Args:
        text: 待过滤的文本
        whitelist: 可选的自定义白名单
        
    Returns:
        dict: 包含过滤结果的字典
    """
    filter_obj = SensitiveFilter(whitelist=whitelist)
    result = filter_obj.filter_content(text)
    return result.to_dict()


def main():
    """命令行入口"""
    import argparse
    
    parser = argparse.ArgumentParser(description="敏感信息过滤器")
    parser.add_argument("text", nargs="?", help="要检查的文本")
    parser.add_argument("-f", "--file", help="从文件读取文本")
    parser.add_argument("-j", "--json", action="store_true", help="JSON 格式输出")
    parser.add_argument("-w", "--whitelist", nargs="+", help="临时白名单关键词")
    args = parser.parse_args()
    
    # 获取文本
    if args.file:
        with open(args.file, 'r', encoding='utf-8') as f:
            text = f.read()
    elif args.text:
        text = args.text
    else:
        # 从 stdin 读取
        import sys
        text = sys.stdin.read()
    
    # 执行过滤
    result = filter_content(text, whitelist=args.whitelist)
    
    # 输出
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"通过检查: {result['passed']}")
        print(f"风险等级: {result['risk_level']}")
        print(f"需人工复核: {result['need_review']}")
        print(f"发现 {len(result['matches'])} 处敏感信息:")
        for m in result['matches']:
            print(f"  - [{m['type']}] {m['masked_value']}")
        print("\n过滤后文本:")
        print(result['filtered_text'])


if __name__ == "__main__":
    main()
