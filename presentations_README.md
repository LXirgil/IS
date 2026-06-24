AI Bowling Master - プレゼン自動生成

このフォルダ内のスクリプトで .pptx を生成します。

必要なパッケージ:
- python-pptx
- pillow (画像挿入が必要な場合)

インストール例 (PowerShell):

```powershell
python -m pip install --upgrade pip
pip install python-pptx pillow
```

生成コマンド:

```powershell
cd C:\Users\14092\IS
python .\scripts\generate_pptx.py
```

出力: `presentations/AI_Bowling_Master.pptx`

画像プレースホルダ:
スライド JSON で指定した画像はワークスペースの相対パス `assets/images/...` を参照します。存在しない場合はプレースホルダは空になります。必要なら画像を `assets/images/` に配置してください。
