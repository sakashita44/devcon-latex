# Instructions for Copilot

## User story

User is not professional of the programming and programming related frameworks.
User is researcher and want to improve the research by using the programming and programming related frameworks.
Therefore, user needs you to explain structure of the code, frameworks and libraries in detail and simple terms.

## General instructions

* If you asked to generate the code, please generate the code.
* It is not necessary to generate the code, until user asks for it.

## Code and documentation rules

### General text rules

* Use `,` and `.` instead of `、` and `。` in Japanese
* Don't use `ですます調` in Japanese and use direct speech, lile example below
    * `~する` instead of `~します`
    * `~できる` instead of `~することができます`
    * `~参照` instead of `~参照する`, `~参照します`
    * `~実行` instead of `~実行する`, `~実行します`

### Markdown rules

* Follow the markdown rules (markdownlint)
* Appearance of the text in the text editor is not important. Follow the markdown rules.
* Use `*` for lists
* Use `1.` for ordered lists continuously
    * Don't use `2.` after `1.`
* Add line break after all heading
* Add line break before and after lists
* Don't use same heading twice
* Don't add numbers in headings
* Add file type for code blocks
* Add `<` and `>` for URLs
* Add back quotes for file paths
* Use `*` for italic text
* Use `**` for bold text
* Don't use meanless bold text
* Don't use meanless headings
* Add back quotes for code and names
* Use 4 spaces for tab
* Add 1 space after list marker and `#` (not 3 spaces)

### Git rules

* Add prefix below for commit message
    * `feat:` for new features
    * `fix:` for bug fixes
    * `refactor:` for code refactoring including formatting and style changes
    * `test:` for adding or modifying tests
    * `docs:` for documentation changes
    * `chore:` for changes to the build process or auxiliary tools and libraries such as documentation generation

### File and folder rules

* Standardize file naming conventions as follows:
    * Repository meta files: all uppercase (README.md, LICENSE, CONTRIBUTING.md, CHANGELOG.md)
    * Project documents: Pascal case - first letter of each word capitalized (Setup.md, Workflow.md, LearningRoadmap.md)
    * Tracking documents: all uppercase with underscores (PROCESS_OVERVIEW.md, VERSION_MAPPING.md)
* Script file naming conventions:
    * Use snake case (process_data.py, analyze_results.py)
    * Start with a verb that represents the function (convert_raw_data.py, calculate_statistics.py)
* Directory names:
    * Use singular form and lowercase (script/, data/, report/)
