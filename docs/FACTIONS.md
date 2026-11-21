# Factions (spike)

Source: owner's description. Mechanics below marked *(draft)* are my proposals, to be confirmed.

## Collectivists
**Identity:** Gather under red flags. Mass and obedience. Will send their last men to death for victory. A strong leader controls everything; the individual is nothing.
**Look:** Brutalist architecture (Soviet Union / North Korea / East Germany, 1980s): massive concrete blocks, few windows, big and heavy. Troops and vehicles are also brutal and massive. Red flags and banners everywhere.
**Play style (draft):**
- Cheap units, built in large batches; strength comes from numbers
- Units never retreat or break (obedience)
- Central command: one dominant HQ ("the Leader") that gives global orders/buffs; losing it hurts badly
- Production by "plans": queue large batches for a discount, delivered late
- Few, large, expensive-to-lose buildings
- Weak individual units, strong group bonuses

## Libertarians
**Identity:** Strength and ideas of the individual. No state-driven structures; voluntariness, freedom of contract, economic freedom.
**Look:** Smaller but more numerous structures; more interaction between units; cities that look organic and varied, not planned.
**Play style (draft):**
- Fewer, individually stronger and more autonomous units (own initiative: auto-behaviors, self-repair/self-supply)
- Many small buildings, no single point of failure
- Contracts: trade and hire mechanics (contractors/mercenaries, trade between buildings) instead of central orders
- Economy bonuses from the number of independent producers
- Flexible, self-organizing; weak against massed assault if caught unprepared

## Contrast axis
Central plan vs. spontaneous order. Mass vs. individual. One big target vs. many small ones.

## Open questions
- Unit roster for the spike (suggest 3 per side: basic infantry, support/harvester, vehicle)
- Resource model: one shared resource or faction-specific flavor of the same resource

## Economy (decided during M4)
- **Materials:** common resource, mined from deposits by harvesters (Laborers / Prospectors) and delivered to the HQ.
- **Second resource:** faction-specific, to be designed in M4b. Direction: Collectivists get a manpower/housing-style cap, Libertarians get a capital/trade-style income.
- **Construction:** Warcraft style, workers walk to the site and build.
- **Names so far:** Collectivist HQ = Central Committee Block, worker = Laborer. Libertarian HQ = Trading Post, worker = Prospector.

## Second resource and building rules (confirmed by owner, M4b)

### Collectivists: Manpower and the Plan
- **Manpower** is a population cap. Housing is spartan: troops are battle-ready, not comfortable. Dormitory Blocks are cheap and fast to build.
- Units and buildings are cheaper and quicker to produce, but weaker per unit than Libertarian ones.
- **The Plan (M4c):** besides single units, production offers batch orders at a discount that take longer and deliver all at once.
- **Planned zone:** Collectivists may only build within a set distance of a finished HQ (strong regulation as a real constraint).

### Libertarians: Capital and Education
- **Capital** is earned by independent Markets (more small buildings means more income). Trade with other peoples (not implemented yet) will boost it.
- Capital buys units, buildings and upgrades. Mercenaries come later.
- **Education:** units train slower and cost more, but are better. No population cap, so Materials and Capital are the limit.
- Libertarians may build anywhere (no regulation).

### Spike roster
| | Collectivists | Libertarians |
|---|---|---|
| HQ | Central Committee Block | Trading Post |
| Second-resource building | Dormitory Block (+8 Manpower) | Market (+1 Capital/s) |
| Production building | Conscription Office | Militia Hall |

Numbers are placeholders in `data/`: Collectivist HQ provides 24 Manpower so the starting army fits (the draft said 10); Libertarians start with 50 Capital; both start with 200 Materials.

## Production and education (confirmed by owner, M4c)
- **Queue** is limited to 5 slots per building. Costs are paid when queued; Manpower is reserved for queued units.
- **Collectivists:** Plan batches (5 Conscripts for 25% less Materials, 20% slower than training 5 one by one, all delivered together).
- **Libertarians, education:** the Militia Hall trains cheap, quick but weaker **Volunteers**. The better **Freeholders** require a finished **Apprentice Workshop** (private, hands-on learning).
- **Universities are reserved for the Collectivists** in this scenario (state institutions), so Libertarian education buildings must never be called universities.
- Units appear in front of the building; rally points may come later.
