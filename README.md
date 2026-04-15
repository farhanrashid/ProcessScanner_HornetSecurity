# Process Scanner
Displays all currently running  processes as a tree.
| Colour | Meaning |
|---|---|
| **Green** | The executable contains `https://` |
| **Sea Green** | At least one descendant process contains `https://` |
| **Red** | `https://` was not found in the executable, and no descendant is green/sea green |
| **Blue** | The executable file could not be opened or read |
| **Black** | Analysis is still pending |

### Time complexity

Let **N** = file size in bytes, **K** = needle length (= 8, a constant).

| Operation | Cost |
|---|---|
| I/O – each byte read exactly once | O(N) |
| Per-byte comparison – at most 2 comparisons per byte in the worst case | O(N) |
| Carry copy per block | O(K) = O(1) |
| **Total** | **O(N)** |
