# Skleník (Greenhouse)

Strategická singleplayer hra v **Godot 4.7+**: pevný 2D pohled na jednu řadu skleníku. Sázíš z ruky karet (start 7), zaléváš, respektuješ světlo jednotlivých slotů a sklízíš na **skóre**. Nové karty jen ze sklizně — větší combo = víc karet.

Cílový vizuální vzor (ne herní asset): [`ref/hud.png`](ref/hud.png). Plán: [`dev_plan.md`](dev_plan.md).

## Stav

Hratelný MVP skeleton: sázení, zálivka, růst po dnech, sklizeň + combo karty, skóre.

## Ovládání

1. Zahraj aspoň 1 kartu (jinak nejde ukončit den).
2. Volný slot: jemné světlo = kolik ☀ dopadá.
3. Zalévat jen když chip hlásí žízeň (závisí na rostlině).
4. Zralé hned skliď — jinak se kazí (rychlé rostliny / víc světla = rychleji).
5. **Ukončit den** — růst při vláze; světlo jen mění tempo.

## Spuštění

Otevři projekt v Godotu 4.7+ a spusť `main.tscn` (F5).
