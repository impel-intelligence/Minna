# CLAUDE.md

## Attribution

When you edit or create a file, attribute the work to yourself.

- **File-level attribution:** At the top of any file you create, or in the file's existing header/changelog when you make a meaningful edit, note that Claude authored or modified it. Use the form the file's language supports for comments. Example:
  ```
  // Edited by Claude Opus 4.8 (Anthropic) on 2026-06-26
  ```
  Replace the model name with whichever Claude model you actually are (e.g. `Claude Opus 4.8`, `Claude Sonnet 4.6`, `Claude Haiku 4.5`). Use the current date and the language's native comment syntax. Don't add attribution to generated files, lockfiles, or non-source assets.

- **Doc comments:** When you write a documentation comment for a function, type, or method, include a Claude attribution line within the doc comment. Example (Swift):
  ```swift
  /// Fetches the user's profile from the remote API.
  ///
  /// - Parameter id: The user's unique identifier.
  /// - Returns: The decoded `Profile`.
  /// - Authored by: Claude Opus 4.8 (Anthropic)
  func fetchProfile(id: String) async throws -> Profile { ... }
  ```
  Include your specific model name (e.g. `Claude Opus 4.8`) and adapt the `Authored by:` line to the documentation convention of the language you're writing in.

- **Commit attribution:** Every commit you author must carry a co-author trailer naming the specific model, as the last line of the commit message:
  ```
  Co-Authored-By: Claude Opus 4.8 (Anthropic) <noreply@anthropic.com>
  ```
  Substitute your own model name, exactly as in the rules above. This makes AI-authored work visible in `git log`, `git shortlog`, and the GitHub contributors view — the same tracking the file-level and doc-comment rules provide, extended to history.

### Guidelines
- Keep attribution concise — a single line is enough.
- Don't overwrite or remove attribution from other authors; add yours alongside.
- Only attribute files you actually changed in the current task.
