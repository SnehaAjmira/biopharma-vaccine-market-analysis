"""Run the SQL pipeline in DuckDB, export result tables, and render figures.

Usage (from the repository root):
    python src/run_analysis.py
"""
from pathlib import Path

import duckdb
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

import style

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "sql"
TABLES = ROOT / "outputs" / "tables"
FIGURES = ROOT / "outputs" / "figures"
SOURCE = "Our World in Data, COVID-19 vaccinations by manufacturer (CC BY 4.0)"


def run_sql(con):
    con.execute((SQL / "00_staging.sql").read_text())
    results = {}
    for path in sorted(SQL.glob("0[1-9]_*.sql")):
        df = con.execute(path.read_text()).df()
        df.to_csv(TABLES / f"{path.stem}.csv", index=False)
        results[path.stem] = df
    return results


def fig_manufacturer_share(df):
    top = df.head(7).iloc[::-1]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    colors = [style.SERIES[0] if m == "Pfizer/BioNTech" else style.NEUTRAL for m in top.manufacturer]
    ax.barh(top.manufacturer, top.share_pct, color=colors, height=0.6)
    for y, v in enumerate(top.share_pct):
        ax.text(v + 0.8, y, f"{v:.1f}%", va="center", fontsize=9, color=style.TEXT)
    ax.xaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.grid(axis="y", visible=False)
    ax.set_xlim(0, max(top.share_pct) * 1.12)
    ax.set_title("Share of reported COVID-19 vaccine doses by manufacturer, 43 countries and territories")
    style.finish(fig, FIGURES / "01_manufacturer_share.png", SOURCE)


def fig_platform_trend(df):
    pivot = df.pivot(index="quarter", columns="platform", values="share_of_quarter_pct").fillna(0)
    pivot.index = [f"Q{(q.month - 1) // 3 + 1} {q.year}" for q in pivot.index]
    order = ["mRNA", "Viral vector", "Inactivated", "Protein-based"]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    for i, p in enumerate(order):
        if p in pivot:
            ax.plot(pivot.index, pivot[p], color=style.SERIES[i], label=p, marker="o", markersize=4)
    ax.yaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.set_ylim(0, 100)
    ax.legend(loc="center right")
    ax.set_title("Share of quarterly doses by vaccine platform, 2020 to 2022")
    style.finish(fig, FIGURES / "02_platform_share_by_quarter.png", SOURCE)


def fig_concentration(df):
    d = df.sort_values("hhi")
    fig, ax = plt.subplots(figsize=(8, 7.5))
    colors = [style.SERIES[1] if h > 5000 else style.SERIES[0] for h in d.hhi]
    ax.barh(d.country, d.hhi, color=colors, height=0.65)
    ax.axvline(2500, color=style.TEXT_2, linewidth=1, linestyle="--")
    ax.text(2550, -1.2, "2,500: highly concentrated", fontsize=8, color=style.TEXT_2)
    ax.grid(axis="y", visible=False)
    ax.tick_params(axis="y", labelsize=8)
    ax.xaxis.set_major_formatter(mtick.StrMethodFormatter("{x:,.0f}"))
    ax.set_xlabel("Herfindahl-Hirschman Index (0 to 10,000)")
    ax.set_title("Supplier concentration by country (orange: HHI above 5,000)")
    style.finish(fig, FIGURES / "03_country_concentration.png", SOURCE)


def main():
    style.apply()
    TABLES.mkdir(parents=True, exist_ok=True)
    FIGURES.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()
    r = run_sql(con)
    fig_manufacturer_share(r["02_manufacturer_share"])
    fig_platform_trend(r["03_platform_by_quarter"])
    fig_concentration(r["04_country_concentration"])
    for name, df in r.items():
        print(f"\n== {name} ==\n{df.head(12).to_string(index=False)}")


if __name__ == "__main__":
    main()
