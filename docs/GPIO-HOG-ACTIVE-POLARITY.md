# GPIO hog / `reset-gpios` — `GPIO_ACTIVE_*` vs the wire (team note)

Linux device tree flags **`GPIO_ACTIVE_LOW`** / **`GPIO_ACTIVE_HIGH`** control how **logical** GPIO values map to **physical** pad voltage — they are **not** optional labels that should “match” the `#` in a net name without derivation.

| Hog / property | Effect on pad |
|----------------|---------------|
| `GPIO_ACTIVE_HIGH` + `output-high` | **Physical high** |
| `GPIO_ACTIVE_LOW` + `output-high` | **Physical low** |
| `GPIO_ACTIVE_LOW` + `output-low` | **Physical high** |

**Example:** `nRESET#` released = pad **high**. You need **physical high** in run mode → e.g. **`GPIO_ACTIVE_HIGH` + `output-high`**, not **`GPIO_ACTIVE_LOW` + `output-high`** (that holds **physical low** = reset asserted).

Buffers/inverters between IC and SoC can **stack** inversions so the **correct** DTS flag looks “inverted” vs the switch datasheet pin. **Source of truth:** measured voltage at the SoC ball for **idle / asserted**.

**Inputs (WoL, IRQ):** the same **`GPIO_ACTIVE_*`** choice defines what Linux considers **active** for level-sensitive and for future IRQ bindings — align with what the **pad** sees, not only the far-end chip naming.

See also: `imx8mm-jaguar-dt510.dts` (`ksz9896_rst` / PME / INTR comments), `docs/DT510-ETHERNET-KSZ9896.md` (PHY **`mdio`** vs **`phytool`** on target), and Foundries bring-up `meta-subscriber-overrides/conf/DT510-HARDWARE-BRINGUP.md`.
