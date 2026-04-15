# Process Scanner
Displays all currently running  processes as a tree.
| Colour | Meaning |
|---|---|
| **Green** | The executable contains `https://`, **or** at least one descendant process does |
| **Red** | `https://` was not found in the executable, and no descendant is green |
| **Blue** | The executable file could not be opened or read |
| **Black** | Analysis is still pending |
