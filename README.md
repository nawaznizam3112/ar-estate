# ar-estate: demo for builders

One shared AR marker, one live page per project, data that the builder can change.

```
ar-estate/
  index.html          viewer (project page + AR tower scene), reads data/projects.json
  data/projects.json  demo data (replace with a database later, see schema.sql)
  make_assets.py      makes the marker, QR codes and sample cards
  dashboard.py        demo builder dashboard (Streamlit)
  schema.sql          production database shape
  targets.mind        YOU create this once (step 2)
```

## 1. Make the assets
```bash
pip install pillow qrcode streamlit
python make_assets.py https://YOURUSERNAME.github.io/ar-estate/
```
This writes `assets/marker.png`, plus a QR and a sample card for each channel partner.

## 2. Compile the marker (once)
Open MindAR’s online image-target compiler, upload `assets/marker.png`, click Start,
download `targets.mind`, and put it next to `index.html`.
Check the heatmap: you want feature points across the whole image.

## 3. Test locally
```bash
python -m http.server 8000
```
Open `http://localhost:8000/?p=greenmeadows&cp=ravi` on your computer.
The project page works straight away. “View in 3D” needs `targets.mind`.
Phones need HTTPS for the camera, so test AR on your phone after step 4.

## 4. Deploy
Push the folder to a public GitHub repo named `ar-estate`, enable Pages (Settings → Pages → main branch).
Then open `https://YOURUSERNAME.github.io/ar-estate/?p=greenmeadows&cp=ravi` on a phone,
and point it at `assets/card_greenmeadows_ravi.png` shown on a screen or printed (matte).

## 5. Show the “update” moment to a builder
```bash
streamlit run dashboard.py
```
Change availability or post a site update, save, push to GitHub, and rescan the same card.
The card is unchanged and the content is new. That is the product.

## What the demo does NOT do yet
- **Leads are not stored.** Without a backend, the form hands the lead to WhatsApp. Set `lead_endpoint` in
  `data/projects.json` to a real endpoint (for example a Supabase Edge Function) to store them.
- **No scan analytics.** The `scans` table in `schema.sql` is where those events would go.
- **No real logins.** The dashboard uses one optional shared password. Use proper auth in production.
- **3D is a generic tower stack,** not the builder’s real model. Real assets (.glb) come per project.
- **Small items:** a tiny keychain may be too small for the marker. Use NFC/QR on keychains, and the AR marker on brochures or table cards.
- **RERA / DPDP:** replace the demo RERA number with the real one, and have compliance approve the content.
