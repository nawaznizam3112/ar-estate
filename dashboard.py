"""
Demo builder dashboard (Streamlit). Edits data/projects.json.

  pip install streamlit
  streamlit run dashboard.py

DEMO ONLY: it writes a local file, then you push to GitHub to publish.
In production, replace load()/save() with database calls (see schema.sql)
and use real logins (e.g. Supabase Auth), not a shared password.
"""
import json
import os
from datetime import date
from pathlib import Path

import streamlit as st

DATA = Path("data/projects.json")
st.set_page_config(page_title="Builder Dashboard", layout="wide")


def load():
    return json.loads(DATA.read_text(encoding="utf-8"))


def save(d):
    DATA.write_text(json.dumps(d, indent=2, ensure_ascii=False), encoding="utf-8")


# Minimal gate. Set DASH_PASSWORD in your environment to enable it.
pw = os.getenv("DASH_PASSWORD")
if pw:
    if st.text_input("Password", type="password") != pw:
        st.stop()
else:
    st.warning("Demo mode: no DASH_PASSWORD set, so anyone with this URL can edit.")

data = load()
base_url = st.sidebar.text_input("Live site URL", "https://YOURUSERNAME.github.io/ar-estate/")
pid = st.sidebar.selectbox("Project", list(data["projects"].keys()))
p = data["projects"][pid]

st.title(p["name"])
st.caption(f"{p['builder']} · {p['location']}")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Status and progress")
    p["status"] = st.text_input("Status", p["status"])
    p["possession"] = st.text_input("Possession", p["possession"])
    p["price_from"] = st.text_input("Price line", p["price_from"])
    p["progress"]["stage"] = st.text_input("Current stage", p["progress"]["stage"])
    p["progress"]["percent"] = st.slider("Percent complete", 0, 100, int(p["progress"]["percent"]))

    st.subheader("Availability")
    for t in p["towers"]:
        t["units_available"] = st.number_input(
            f"{t['name']}: units available (of {t['units_total']})",
            min_value=0, max_value=int(t["units_total"]), value=int(t["units_available"]), key=f"av_{t['name']}",
        )

with col2:
    st.subheader("Post an update")
    new_text = st.text_area("What happened on site?", placeholder="Tower A: 8th floor slab cast.")
    if st.button("Add update") and new_text.strip():
        p["updates"].insert(0, {"date": date.today().isoformat(), "text": new_text.strip()})
        save(data)
        st.success("Update added.")

    st.subheader("Recent updates")
    for u in p["updates"][:5]:
        st.write(f"**{u['date']}**  {u['text']}")

    st.subheader("Channel partner links")
    st.write(f"Direct: {base_url}?p={pid}")
    for code, cp in (p.get("cps") or {}).items():
        st.write(f"{cp['name']}: {base_url}?p={pid}&cp={code}")

if st.button("Save changes", type="primary"):
    save(data)
    st.success("Saved to data/projects.json. Commit and push to publish.")
