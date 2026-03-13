#!/usr/bin/env python3
"""
godot_api_docs.py — Godot API XML → Markdown 변환 + 클래스 검색
Godot 공식 API XML 문서를 Markdown으로 변환하여 LLM이 참조할 수 있게 합니다.
"""

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


DOC_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "doc_api")


def ensure_docs(godot_version: str = "4.3"):
    """Godot API 문서 XML이 없으면 다운로드"""
    xml_dir = os.path.join(DOC_DIR, "xml")
    if os.path.exists(xml_dir) and os.listdir(xml_dir):
        return xml_dir

    print(f"Downloading Godot {godot_version} API docs...")
    os.makedirs(xml_dir, exist_ok=True)

    # godot-docs 레포의 classes XML
    import urllib.request
    import zipfile
    import io

    url = f"https://github.com/godotengine/godot/archive/refs/tags/{godot_version}-stable.zip"
    try:
        with urllib.request.urlopen(url, timeout=120) as resp:
            zip_data = io.BytesIO(resp.read())

        with zipfile.ZipFile(zip_data) as zf:
            prefix = f"godot-{godot_version}-stable/doc/classes/"
            for name in zf.namelist():
                if name.startswith(prefix) and name.endswith(".xml"):
                    class_name = os.path.basename(name)
                    with zf.open(name) as src:
                        with open(os.path.join(xml_dir, class_name), "wb") as dst:
                            dst.write(src.read())

        print(f"OK: {len(os.listdir(xml_dir))} class docs extracted → {xml_dir}")
    except Exception as e:
        print(f"WARNING: Failed to download docs: {e}", file=sys.stderr)

    return xml_dir


def xml_to_markdown(xml_path: str) -> str:
    """단일 Godot 클래스 XML을 Markdown으로 변환"""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    name = root.get("name", "Unknown")
    inherits = root.get("inherits", "")
    brief = root.findtext("brief_description", "").strip()
    desc = root.findtext("description", "").strip()

    lines = [f"# {name}"]
    if inherits:
        lines.append(f"\n**Inherits**: {inherits}")
    if brief:
        lines.append(f"\n{brief}")
    if desc:
        lines.append(f"\n## Description\n\n{desc}")

    # Properties
    members = root.find("members")
    if members is not None and len(members):
        lines.append("\n## Properties\n")
        lines.append("| Type | Name | Default |")
        lines.append("|------|------|---------|")
        for m in members:
            mtype = m.get("type", "")
            mname = m.get("name", "")
            mdefault = m.get("default", "")
            lines.append(f"| {mtype} | {mname} | {mdefault} |")

    # Methods
    methods = root.find("methods")
    if methods is not None and len(methods):
        lines.append("\n## Methods\n")
        for method in methods:
            mname = method.get("name", "")
            ret = method.find("return")
            ret_type = ret.get("type", "void") if ret is not None else "void"
            params = []
            for p in method.findall("param"):
                pname = p.get("name", "")
                ptype = p.get("type", "")
                pdefault = p.get("default", "")
                param_str = f"{pname}: {ptype}"
                if pdefault:
                    param_str += f" = {pdefault}"
                params.append(param_str)
            sig = f"**{mname}**({', '.join(params)}) → {ret_type}"
            lines.append(f"- {sig}")
            desc = method.findtext("description", "").strip()
            if desc:
                lines.append(f"  {desc[:200]}")

    # Signals
    signals = root.find("signals")
    if signals is not None and len(signals):
        lines.append("\n## Signals\n")
        for sig in signals:
            sname = sig.get("name", "")
            params = []
            for p in sig.findall("param"):
                params.append(f"{p.get('name', '')}: {p.get('type', '')}")
            lines.append(f"- **{sname}**({', '.join(params)})")
            desc = sig.findtext("description", "").strip()
            if desc:
                lines.append(f"  {desc[:200]}")

    return "\n".join(lines)


def search_class(class_name: str) -> str:
    """클래스 문서 검색 → Markdown 반환"""
    xml_dir = ensure_docs()
    xml_path = os.path.join(xml_dir, f"{class_name}.xml")

    if not os.path.exists(xml_path):
        # 대소문자 무시 검색
        for f in os.listdir(xml_dir):
            if f.lower() == f"{class_name.lower()}.xml":
                xml_path = os.path.join(xml_dir, f)
                break
        else:
            return f"ERROR: Class '{class_name}' not found in API docs"

    return xml_to_markdown(xml_path)


def list_classes() -> list:
    """사용 가능한 클래스 목록 반환"""
    xml_dir = ensure_docs()
    return sorted(
        f.replace(".xml", "")
        for f in os.listdir(xml_dir)
        if f.endswith(".xml")
    )


def main():
    parser = argparse.ArgumentParser(description="Godot API docs tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # search
    search_p = subparsers.add_parser("search", help="Search class docs")
    search_p.add_argument("class_name", help="Godot class name")

    # list
    subparsers.add_parser("list", help="List available classes")

    # ensure
    ensure_p = subparsers.add_parser("ensure", help="Download/update API docs")
    ensure_p.add_argument("--version", default="4.3", help="Godot version")

    args = parser.parse_args()

    if args.command == "search":
        print(search_class(args.class_name))
    elif args.command == "list":
        classes = list_classes()
        print(f"Available classes ({len(classes)}):")
        for c in classes:
            print(f"  {c}")
    elif args.command == "ensure":
        ensure_docs(args.version)


if __name__ == "__main__":
    main()
