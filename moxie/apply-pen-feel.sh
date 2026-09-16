#!/bin/bash
set -euo pipefail

ROOT="${1:?Rnote source directory required}"
INPUT="$ROOT/crates/rnote-ui/src/canvas/input.rs"
MODELER="$ROOT/crates/rnote-compose/src/builders/penpathmodeledbuilder.rs"

python3 - "$INPUT" "$MODELER" <<'PY'
from pathlib import Path
import sys

input_path = Path(sys.argv[1])
modeler_path = Path(sys.argv[2])

s = input_path.read_text()

needle = '''fn event_is_stylus(event: &gdk::Event) -> bool {\n    // As in gtk4 'gtkgesturestylus.c:106' we detect if the pointer is a stylus when it has a device tool\n    event.device_tool().is_some()\n}\n'''
replacement = '''fn event_is_stylus(event: &gdk::Event) -> bool {\n    // As in gtk4 'gtkgesturestylus.c:106' we detect if the pointer is a stylus when it has a device tool\n    event.device_tool().is_some()\n}\n\n// Moxie pen feel: preserve full pressure range while making light strokes easier to control.\n// The curve is intentionally mild so the source pressure still feels natural.\n#[inline]\nfn moxie_pressure(pressure: f64) -> f64 {\n    const GAMMA: f64 = 0.86;\n    pressure.clamp(0.0, 1.0).powf(GAMMA)\n}\n'''
if needle not in s:
    raise SystemExit('input.rs anchor not found')
s = s.replace(needle, replacement, 1)

old = '''            let pressure = if is_stylus {\n                axes[crate::utils::axis_use_idx(gdk::AxisUse::Pressure)]\n            } else {\n                Element::PRESSURE_DEFAULT\n            };\n\n            entries.push((Element::new(pos, pressure), entry_time));'''
new = '''            let pressure = if is_stylus {\n                moxie_pressure(axes[crate::utils::axis_use_idx(gdk::AxisUse::Pressure)])\n            } else {\n                Element::PRESSURE_DEFAULT\n            };\n\n            entries.push((Element::new(pos, pressure), entry_time));'''
if old not in s:
    raise SystemExit('input.rs backlog pressure anchor not found')
s = s.replace(old, new, 1)

old = '''    let pressure = if is_stylus {\n        event.axis(gdk::AxisUse::Pressure).unwrap()\n    } else {\n        Element::PRESSURE_DEFAULT\n    };'''
new = '''    let pressure = if is_stylus {\n        moxie_pressure(event.axis(gdk::AxisUse::Pressure).unwrap())\n    } else {\n        Element::PRESSURE_DEFAULT\n    };'''
if old not in s:
    raise SystemExit('input.rs current pressure anchor not found')
s = s.replace(old, new, 1)
input_path.write_text(s)

m = modeler_path.read_text()
old = '''static MODELER_PARAMS: Lazy<ModelerParams> = Lazy::new(|| ModelerParams {\n    sampling_min_output_rate: 120.0,\n    sampling_end_of_stroke_stopping_distance: 0.01,\n    sampling_end_of_stroke_max_iterations: 20,\n    sampling_max_outputs_per_call: 200,\n    stylus_state_modeler_max_input_samples: 20,\n    ..ModelerParams::suggested()\n});'''
new = '''static MODELER_PARAMS: Lazy<ModelerParams> = Lazy::new(|| ModelerParams {\n    // Moxie: keep a high output cadence for handwriting while retaining the\n    // modeler's prediction and smoothing. This reduces visible stepping when\n    // the pen moves quickly without disabling input backlog handling.\n    sampling_min_output_rate: 180.0,\n    sampling_end_of_stroke_stopping_distance: 0.01,\n    sampling_end_of_stroke_max_iterations: 24,\n    sampling_max_outputs_per_call: 300,\n    stylus_state_modeler_max_input_samples: 24,\n    ..ModelerParams::suggested()\n});'''
if old not in m:
    raise SystemExit('modeler params anchor not found')
m = m.replace(old, new, 1)
modeler_path.write_text(m)
PY

echo "Moxie pen-feel tuning applied to Rnote source."
