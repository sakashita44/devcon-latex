# Instructions for Copilot

## User Story

The user is a researcher, not a professional programmer. They want to use programming and related frameworks to improve their research. Therefore, the user needs you to explain the structure of code, frameworks, and libraries in detail and in simple terms.

## Definition of Rule Levels

* **[Must]**: Always follow this rule, regardless of user input. This is a strict, non-negotiable instruction.
* **[Should]**: This is the default behavior. However, this rule can be skipped or modified if the user explicitly requests otherwise.

---

## Session Start Procedure

* **[Must]** **Understand the Goal**: At the very beginning of the session, read the `README.md` file in the root directory to understand the main purpose and overview of the repository.
* **[Must]** **Confirm the Environment**: Check for the existence of a `.devcontainer` directory in the root to confirm that the session is running within the expected containerized environment.

---

## Guiding Principles

### Interactive Requirement Gathering

* **[Must]** When a request for code generation is complex, ambiguous, or lacks specific details, do not generate code immediately.
* **[Should]** First, initiate a dialogue with the user to clarify the requirements. The goal is to understand:
  * **The overall objective**: What is the ultimate goal?
  * **Inputs**: What data will be used (format, source, etc.)?
  * **Outputs**: What is the expected result (format, content, etc.)?
  * **Constraints and edge cases**: Are there any special conditions to consider?

### Error Handling Procedure

* **[Must]** When an error occurs, do not immediately provide the corrected code. Instead, follow this interactive process:
  1.  **Share and Explain**: Present the full error message to the user.
  2.  **Suggest Causes**: Propose likely causes for the error based on the message and the current context.
  3.  **Propose a Solution**: After discussing the causes, suggest a specific solution and get the user's agreement before implementing the fix.
* **[Must]** Show error messages inside a fenced code block with the type `text` and with no truncation.
* **[Should]** Provide a one-sentence summary in plain text after the error block.

---

## Code Generation Strategy

### Granularity and Interaction

* **[Must]** Generate code at most one function or class per step.
* **[Must]** After generating each unit, stop and ask for confirmation before continuing.
* **[Should]** **Scaffolding First**: When generating a new script for the first time, it can be helpful to provide only the skeleton of the code (function/class definitions with placeholders) to agree on the overall structure first.

### Comments and Documentation

* **[Must]** Provide Japanese docstring comments for all functions and classes.
* **[Should]** Provide inline Japanese comments only for non-trivial or complex logic that is not self-explanatory.

### Code Style

* **[Should]** **Backward Compatibility**: By default, provide clean, modern code that does not prioritize backward compatibility. If you identify a potential need for it, consult with the user to confirm before implementing a compatibility-focused solution.

---

## Technical Rules

### Execution and Git Rules

#### General Execution

* **[Must]** **One-by-one Execution**: Execute all terminal commands one by one. Always check the output of each command for success or errors before proceeding to the next.
* **[Should]** **Directory Check**: Before running a script, execute the `pwd` command to confirm you are in the correct directory.

#### Git Safety

* **[Must]** Never execute `git add .` or `git add -A` without first running `git diff` and showing the changes to the user for approval.
* **[Must]** Always show the full commit message proposal to the user and get approval before running `git commit`.
* **[Must]** Never delete, amend, or squash commits without explicit user instruction.
* **[Must]** **No Pushing**: Do not push to the remote repository (`git push`).

#### Git Workflow

* **[Should]** **Commit Message Prefixes**: Use the following prefixes for commit messages:
  * `feat:` for new features.
  * `fix:` for bug fixes.
  * `refactor:` for code refactoring.
  * `test:` for adding or modifying tests.
  * `docs:` for documentation changes.
  * `chore:` for build process or auxiliary tool changes.
* **[Should]** **Pre-commit Testing**: Always test scripts before committing to ensure they work correctly.

### File and Folder Rules

* **[Must]** Do not rename existing files without explicit user instruction.
* **[Should]** Follow the naming conventions below, but allow flexibility for small, exploratory scripts.
  * **Repository meta files**: All uppercase (`README.md`, `LICENSE`).
  * **Project documents**: PascalCase (`Workflow.md`).
  * **Script files**: snake_case, starting with a verb (`process_data.py`).
  * **Directory names**: singular form and lowercase (`script/`, `data/`).

### Note Taking

* **[Should]** Append any agreed-upon points or new instructions to the `/notes.tmp` file (create the file if it doesn't exist).

---

## Appendix: Detailed Formatting and Style Guides

### General Text Rules

* **[Should]** Use `,` and `.` for punctuation.
* **[Should]** Use a direct and concise tone. Avoid overly formal or polite language.
  * Use imperatives like `run` instead of `you should run`.
  * Use `can` instead of `it is possible to`.
  * Use direct verbs like `refer to` or `execute`.

### Markdown Rules

* **[Should]** Follow standard markdown rules (markdownlint).
* The appearance of text in the text editor is not important; adherence to markdown rules is.
* Use `*` for unordered lists.
* Use `1.` for all items in an ordered list (e.g., `1.`, `1.`, `1.`).
* Add a line break after every heading.
* Add a line break before and after lists.
* Do not use the same heading text twice.
* Do not add numbers in headings.
* Specify the file type for code blocks.
* Enclose URLs in angle brackets: `<https://example.com>`.
* Enclose file paths in backticks: `` `path/to/file.md` ``.
* Use `*` for *italic* text.
* Use `**` for **bold** text.
* Do not use bold text without a clear purpose.
* Do not use headings without a clear purpose.
* Enclose code and technical names in backticks.
* Use 4 spaces for indentation (tab).
* Use only one space after list markers (`*`, `1.`) and heading markers (`#`).
