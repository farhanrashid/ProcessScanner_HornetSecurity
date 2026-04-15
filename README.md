# Process Scanner
Displays all currently running  processes as a tree.
| Colour | Meaning |
|---|---|
| **Green** | The executable contains `https://` |
| **Sea Green** | At least one descendant process contains `https://` |
| **Red** | `https://` was not found in the executable, and no descendant is green/sea green |
| **Blue** | The executable file could not be opened or read |
| **Black** | Analysis is still pending |
