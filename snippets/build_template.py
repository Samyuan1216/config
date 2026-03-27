import json
import os

# 为你的模板划分逻辑模块
modules = {
    "一、 基础配置与工具": [
        "init.json", "FastIO.json", "flat index.json"
    ],
    "二、 数据结构": [
        "DSU.json", "priority queue.json", "custom hash.json", "HashTable.json", 
        "binary index tree.json", "Seg.json", "AVL tree.json", "Splay.json", 
        "Treap.json", "FHQ Treap1.json", "FHQ Treap2.json", "rbtree.json", 
        "Scape Goat.json", "Descartes Tree.json", "Skip List.json"
    ],
    "三、 图论": [
        "dijkstra.json", "spfa.json", "bellman ford.json", "floyd.json",
        "prim.json", "kruskal.json"
    ],
    "四、 树论": [
        "lca1.json", "lca2.json", "tree diameter1.json", "tree diameter2.json",
        "tree centroid1.json", "tree centroid2.json"
    ],
    "五、 字符串": [
        "Trie.json", "AC.json", "kmp.json", "kmp_next.json",
        "manacher.json", "zarray.json", "earray.json"
    ],
    "六、 数学与数论": [
        "Modint.json", "Bigint.json", "power.json", "matrix multiply.json", "matrix power.json",
        "fact.json", "inv1.json", "inv2.json", "C1.json", "C2.json",
        "exgcd.json", "euler.json", "base convertion.json"
    ],
    "七、 算法基础与动态规划": [
        "binary search1.json", "binary search2.json", "binary search3.json", "binary search4.json",
        "digit dp.json", "euclidean distance.json", "manhatten distance.json", "diagonal distance.json"
    ]
}

md_content = "# 算法竞赛模板 (C++)\n\n[TOC]\n\n"

for module, files in modules.items():
    # 强制在 Markdown 中实现分页，避免打印时标题处于页面底部
    md_content += f'<div style="page-break-before: always;"></div>\n\n'
    md_content += f"## {module}\n\n"
    
    for filename in files:
        filepath = os.path.join("cpp", filename)
        if not os.path.exists(filepath):
            print(f"⚠️ 找不到文件: {filepath}")
            continue
        
        with open(filepath, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                # 获取 snippet 内容
                key = list(data.keys())[0]
                snippet = data[key]
                description = snippet.get("description", filename.replace(".json", ""))
                body = snippet.get("body", [])
                
                md_content += f"### {description}\n\n"
                md_content += "```cpp\n"
                md_content += "\n".join(body)
                md_content += "\n```\n\n"
            except Exception as e:
                print(f"❌ 处理 {filename} 时出错: {e}")

with open("ACM_Template.md", "w", encoding="utf-8") as f:
    f.write(md_content)

print("✅ 模板生成成功！已保存为 ACM_Template.md")
