# Skleník — vývojový plán

*Aktualizace: 24. 10. 2026 · cílový vzor (ne asset): [`ref/hud.png`](ref/hud.png)*

Strategická singleplayer hra v Godot 4.7+: pevný 2D pohled na jednu řadu
skleníku, sázení kartami, světlo podle slotu, zalévání bez limitu vody,
skóre ze sklizní a combo za vícenásobnou sklizeň.

---

## 1. Pitch

Hráč **spravuje jednu dřevěnou řadu záhonů** jako pracovní stůl. Myší
vybírá sloty, hraje karty sazenic, zalévá, respektuje různé osvětlení
slotů a ukončuje dny tak, aby dozrálo co nejvíc rostlin najednou.

**Háček:** úvodní ruka je konečná zásoba karet — nové karty přicházejí
jen ze sklizně. Větší **combo sklizeň** = víc karet do ruky = silnější
další dny. Cíl je **skóre**.

**Bez ekonomiky mincí.** Žádný zisk, žádné ceny karet.

---

## 2. Vizuální bible

`ref/hud.png` je **cílový vzor** layoutu a art směru — **nikdy se
nenačítá ve hře**. Runtime art patří do `assets/` (aktuálně
`assets/greenhouse/greenhouse_backdrop.jpg`). Herní pravidla v tomto
dokumentu mají přednost, pokud se mockup liší.

### Scéna (svět)

| Vrstva | Co je na mockupu | Herní role |
|--------|------------------|------------|
| Pozadí | Skleněné tabule, dřevěná konstrukce, paprsky shora zprava | Backdrop; paprsky vizuálně ladí se **světlem slotů** |
| Visuté sloty | 3 závěsné květináče | Samostatná řada výsadby |
| Střední řada | Papriky v různých fázích | Vysoké rostliny |
| Spodní řada | Zelí / nízké | Nízké rostliny |
| Props | Sudy, ventilátor, monitor, clipbord, listí | Atmosféra / diegetické UI |
| Půda | Dřevěný truhlík, mřížka slotů (~5 sloupců) | Interaktivní grid |

Pohled: **pevná kamera**, mírný nadhled. Žádný free roam.

### HUD (cílové chování — odchylky od mockupu)

- **Vlevo nahoře — status panel:**
  - `Den N` + sezóna (volitelně)
  - **`Skóre`** (místo Zisku / mincí)
  - Globální bary **Voda** a **Světlo jako zásoby pryč** — voda není
    omezená; světlo je vlastnost slotu (viz 4.4)
- **Dole — ruka karet:** start **7**; může růst podle lizů ze sklizně.
  Na kartě: druh, art, doba růstu, potřeba světla / zalévání. **Bez mincí.**
- **Vlevo dole — balíček:** neukazuje zbývající karty (balíček je
  neomezený). Tlačítko `Karty` = info / prohlížení typů (volitelné).
- **Vpravo dole — kontextový prompt** (např. `Vybrat místo pro výsadbu`)
- **Diegeticky vpravo:** monitor, clipbord s odpočty do sklizně

### World-space UI

U rostlin: potřeba zálivky (kapka), indikace zda slot dává dost světla,
progress růstu. U hanging pots bubliny s kapkou podle mockupu.

### Art směr

Teplá přírodní paleta, ručně kreslená / painterly ilustrace, měkké
stíny, čitelné UI, čeština.

---

## 3. Herní smyčka

```
Start běhu
  → líznout úvodní ruku: přesně 7 karet (z weight tabulky)
  → skóre = 0, den = 1

Během dne
  → hráč může zahrát libovolný počet karet z ruky do volných slotů
  → zalévá rostliny (voda neomezená — jen péče)
  → plánuje podle světla slotů (fixní mapa světla)
  → sklízí ready rostliny (klik / dávka — viz 4.5)
       • každá sklizená sazenice: +skóre, +1 karta do ruky
       • sklizeň N>1 najednou = combo → bonusové karty
  → hráč ukončí den

Další den
  → růst +1 den u zasazených (pokud splněna péče / světlo)
  → ruka se NEDOPLŇUJE na začátku dne
  → hráč hraje dál s kartami, které má (včetně včerejších lizů)
```

Hráč **nechodí po mapě**. Akce = klik do scény + karty + HUD.

---

## 4. Systémy

### 4.1 Prostor a sloty

- Záhon: **grid** (návrh ≈ **5 sloupců × 2 řady**: low / tall).
- **Visutá řada** (≈ 3 hanging) — oddělené sloty.
- Max 1 rostlina / slot.
- Každý slot má `light_level` (float nebo enum: low / mid / high) —
  statická mapa pro daný skleník (vizuálně paprsky ve vzoru / backdropu).

### 4.2 Karty a neomezený balíček

`PlantDef` (Resource) — bez mincí:

| Pole | Význam |
|------|--------|
| id / display_name | `rajce`, Rajče |
| border_color | barva okraje karty |
| growth_days | dny do sklizně |
| light_need | ideální světlo; méně = pomalejší růst |
| water_interval_days | jak často musí být zalitá |
| allowed_rows | nepoužívá se — každý slot pro každou sazenici |
| score_value | body za sklizeň této rostliny |
| art | card face / world sprite |

**Úvodní ruka:** 7 karet. **Během dne:** libovolný počet zahrání.
**Doplnění ruky jen ze sklizně**, ne na začátku dne.

**Balíček = weighted random, neomezený.** Samostatný data soubor, např.
`data/draw_table.json` nebo `data/draw_table.tres`:

```text
# váhy líznutí (součet nemusí být 100 — normalizuje se)
rajce: 20
zeli: 20
paprika: 15
bazalka: 25
levandule: 20
```

Každé líznutí (úvodní ruka i odměna ze sklizně) bere z této tabulky.
Žádný discard reshuffle finite decku.

### 4.3 Combo a odměna karet

Při jedné sklizňové akci (více ready rostlin sklizených najednou):

| Sklizeno N | Karty do ruky |
|------------|---------------|
| 1 | 1 (základ: 1 za rostlinu) |
| 2 | 2 + bonus_combo(2) |
| 3 | 3 + bonus_combo(3) |
| … | N + bonus_combo(N) |

**Pracovní vzorec bonus_combo (laditelný):**

```text
bonus_combo(N) = 0           pokud N <= 1
bonus_combo(N) = N - 1       pokud N >= 2
# tedy 2→+1, 3→+2, 4→+3 … celkem karet = 2N - 1 pro N>=2
```

Příklad: sklizeň 3 sazenic → 3 základní + 2 bonus = **5 karet**.

### 4.4 Světlo a voda

**Světlo — podle slotu, ne globální bar:**

- Slot má fixní `light_level`.
- Rostlina má `light_need`. Při plném světle +1.0 den/den; při
  nedostatku **roste pomaleji** (1 stupeň = 0.5, 2 stupně = 0.25).
- Hráč volí slot podle paprsků (rychlost), ne podle zákazu výsadby.
- **Každý slot přijme každou sazenici.**

**Voda — neomezená, frekvence podle rostliny:**

- Každá rostlina má `water_interval_days` (vláha vydrží N dní).
- Zálivka jen když `needs_water` (vláha došla) — ne povinně každý den.
- Bez vláhy rostlina neroste (stejně jako při nedostatku světla slotu).
- Kapky / červené rámy = reminder, ne spotřeba resource poolu.

**Konec dne:**

- Povinné zahrát **alespoň 1 kartu** v daném dni, jinak nelze ukončit den.

### 4.5 Růst, sklizeň, skóre, kažení

- Instance: `days_elapsed` / `days_required`.
- Po dozrání musí hráč **sklidit**. Nesklizená zralá sazenice se **kazí**.
- Tempo kažení = tempo růstu: `spoil_rate = light_rate * (3 / growth_days)`.
  Rychlé rostliny / plné světlo → kratší okno na sklizeň.
- Po `spoil_progress >= 1` sazenice zmizí bez skóre a bez karet.
- Konec dne: pokud zálivka OK a světlo slotu OK → `days_elapsed += 1`.
- Ready → hráč sklízí (jednu nebo víc najednou = combo).
- Každá sklizená rostlina: `score += plant.score_value`.
- Slot se uvolní; líznou se karty dle 4.3.

### 4.6 Cíl hry

- Hra na **skóre** (high score / běh na N dní / do prázdné ruky bez
  ready rostlin — přesný konec běhu viz otevřené).
- MVP: sledovat skóre + den; win condition doladit později.

### 4.7 Vstup

- LPM: výběr karty → slot; zálivka; sklizeň; ukončení dne.
- Prompt vpravo dole = aktuální očekávaná akce.

---

## 5. Godot architektura

```
res://
  assets/
  data/
    plants/           # PlantDef .tres
    draw_table.tres   # váhy líznutí (neomezený balíček)
  scenes/
    main.tscn
    plants/
    ui/
  scripts/
    game/             # DayClock, Score, DrawTable, Hand
    plants/
    ui/
  autoload/           # EventBus, GameState
```

### Scénový strom (logický)

```
Main (Node2D)
├── GreenhouseView
│   ├── BedGrid              # sloty + light_level
│   ├── HangingRow
│   └── WorldSpaceUI
├── HUD (CanvasLayer)
│   ├── StatusPanel          # den, sezóna, skóre
│   ├── Hand                 # start 7 CardView
│   ├── DeckWidget           # info (bez finite count)
│   └── ActionPrompt
└── Systems
    ├── DayClock
    ├── ScoreService
    ├── DrawTable            # weighted random
    └── HandController
```

**Signal up, call down.** Godot MCP na scény/run; nové viditelné části
→ generovat asset do `assets/` ve stylu `ref/hud.png`.

---

## 6. MVP milníky

1. Skeleton scény + grid slotů s `light_level`.
2. `PlantDef` + `draw_table` + úvodní ruka 7.
3. Sázení libovolného počtu karet ze dne.
4. Zálivka (neomezená) + růst jen při splnění světla/zálivky.
5. Sklizeň → skóre + líznutí karet + combo bonus.
6. Ukončení dne bez doplnění ruky.
7. HUD: den, skóre, ruka, prompt (bez mincí / bez resource barů).

---

## 7. Startovní rostliny

| Rostlina  | Řada (návrh) | Dny | light_need | score_value |
|-----------|--------------|-----|------------|-------------|
| Rajče     | tall         | 4   | mid        | 10          |
| Zelí      | low          | 5   | low        | 8           |
| Paprika   | tall         | 6   | high       | 14          |
| Bazalka   | hanging/low  | 3   | mid        | 7           |
| Levandule | hanging      | 5   | high       | 12          |

Váhy líznutí a skóre jsou laditelné v datech.

---

## 8. Stále otevřené

1. Přesný konec běhu (fixed dny vs. soft fail při prázdné ruce).
2. Finální `bonus_combo(N)` křivka.
3. Přesný grid (5×2 + 3 hanging?).
4. Mapa `light_level` po slotech (ruční layout vs. z artu paprsků).
5. Sklizeň jen ručně, nebo i auto-prompt „Sklidit combo“?
6. Sezóna / monitor — flavour nebo mechanika?

---

## 9. Reference (stručně)

Částečně blízko: karetní farmářky a spatial garden puzzle.
Odlišnost: **fixní 2D záhon, světlo per-slot, voda jen jako péče,
neomezený weighted deck, skóre + combo → karty**.

---

## Design decisions

### 2026-10-24 — Engine a dokumentace
**Decision:** Godot 4.7+; Godot MCP; design sem; `README.md` snapshot.
**Why:** Tooling a paměť mimo chat.

### 2026-10-24 — Assety ke scénám
**Decision:** Nová viditelná část scény → asset hned do `assets/`; styl =
existující assety / `ref/hud.png`; při nejistotě se zeptat. `ref/` se
nenačítá ve hře.
**Why:** Konzistence.

### 2026-10-24 — Vizuální kotva
**Decision:** `ref/hud.png` = layout + art bible (jen reference); pravidla
v plánu mají přednost při rozporu s mockup UI.
**Why:** Mockup je starší než aktuální mechaniky.

### 2026-10-24 — Bez mincí, skóre, combo deck
**Decision:** Žádné mince. Cíl = skóre za sklizně. Úvodní ruka 7, bez
denního draw. Libovolný počet her za den. 1 karta za sklizenou sazenici
+ bonus karty za combo (větší N = větší bonus). Neomezený balíček =
soubor vah. Světlo per-slot. Voda neomezená, jen povinné zalévání.
**Why:** Požadavek designu — tempo z komba a péče, ne z ekonomiky.

### 2026-10-24 — MVP implementace
**Decision:** Hratelný skeleton v Godot 4.7: `GameState` autoload,
`PlantDef` + `data/draw_table.tres`, grid 5×2 + 3 hanging, HUD (den,
skóre, ruka, sklizeň, ukončit den), backdrop v `assets/greenhouse/`,
slot art `assets/greenhouse/slot_soil.jpg`.
**Why:** První hratelná smyčka podle plánu.

### 2026-10-24 — Stavy, zálivka, konec dne
**Decision:** Slot UI = diegetické chipy + barevný rám podle stavu
(žízeň / stín / růst / sklizeň), ne plné desky přes art. Zálivka podle
`water_interval_days` rostliny (vláha vydrží N dní). Ukončení dne jen
pokud hráč ten den zahrál ≥1 kartu.
**Why:** Blíž cílovému vzoru, čitelnější stavy, méně klikací rutiny.

### 2026-10-24 — hud.png není asset
**Decision:** `hud.png` přesunuto do `ref/` s `.gdignore`. Ve hře se
používá jen vygenerovaný `assets/greenhouse/greenhouse_backdrop.jpg`.
**Why:** Mockup = cíl stylu, ne runtime textura.

### 2026-10-24 — Sloty v hlíně
**Decision:** Herní sloty jsou velké (~200×150) a leží v truhlíku s
hlínou na backdropu (zadní + přední řada); hanging nad záhonem.
**Why:** Čitelnost a shoda s art pozadím.

### 2026-10-24 — Svetlo a univerzalni sloty
**Decision:** Nedostatek svetla jen zpomaluje rust (0.5 / 0.25),
nezastavuje ho. Kazda sazenice jde do kteréhokoli slotu.
**Why:** Flexibilnejsi planovani, svetlo = tempo ne hard gate.

### 2026-10-24 — Kazeni zralych sazenic
**Decision:** Nesklizena zrala sazenice se kazi; rychlost kazeni kopiruje
rychlost rustu (`light_rate * 3 / growth_days`). Po 100 % kazeni zmizi
bez odmeny.
**Why:** Tlak na vcasnou sklizen a combo timing.
