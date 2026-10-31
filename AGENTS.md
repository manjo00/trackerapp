# AGENTS.md: Uplan

For any AI working on this project: Codex, Gemini, Cursor, Antigravity, Claude and the like.

## Before anything else, read
1. `CLAUDE.md`. All of it applies to you, not only to Claude. Its START HERE block says where the project stands and what the traps are.
2. `docs/_Current_Task.md`: the task in hand, the exact stop point and the next step.
3. The last 5 lines of `docs/_Task_History.md`.

Then read `docs/_Master_Plan.md` when choosing what's next, and `graphify-out/GRAPH_REPORT.md` for a map of the code.

## After every task
Tick the item in `docs/_Master_Plan.md`. Add one line to `docs/_Task_History.md` (`date | task | files | commit | notes`; never edit old lines). Update `docs/_Current_Task.md` and the START HERE block in `CLAUDE.md`. Commit and push. Write for a reader who knows nothing about your chat.

## Working with Ahmed (the owner)
He is not a programmer. Use plain words, and explain a new idea in 2-3 sentences before using it. Ask one question at a time. For a real choice, give numbered options with the recommended one first, marked "(Recommended)". Never claim something works without checking it. Ask before installing anything or changing a system setting, and never change Windows Smart App Control.

<!-- working-with-ahmed:start (from D:\projects\claude-setup\templates\working-with-ahmed.md: change it there first, then in every project) -->
## Working with Ahmed (every chat and AI app)
On Ahmed's PC these rules load by themselves from `C:\Users\kille\.claude\CLAUDE.md`. In a tablet (cloud) chat or
another AI app, read `CLAUDE.md` in his private GitHub repo `manjo00/claude-setup` first if you can reach it. "The
Manager" is his chat on the PC that keeps those rules. Either way, follow at least this:
- **Who he is:** not a programmer; he directs, you build and explain. Answer in plain English (he may write in
  Arabic), define any new term the first time, and describe bugs as behaviour, never as error dumps.
- **Short replies, same quality:** the answer, the facts behind it and his choice come first, in about 150 words.
  Nothing important gets cut: long details go into a notes file or a page he can open on the tablet.
- **Questions:** one at a time. Real choices as numbered options with short trade-offs, the recommended one first and
  marked "(Recommended)". Exact click paths for anything he does by hand.
- **Challenge first:** restate the task in a sentence or two, push back on anything unclear or unsafe, then do what he
  decides.
- **Demo first:** a quick working version before any big process. Say the size and a time range before starting; past
  twice the estimate, stop and ask him. When ideas, plans or designs are being shaped, use the brainstorming skill if
  you have it, taking the parts that fit.
- **Research says its cost first:** before looking things up, say the time and the rough usage. Try your own searches
  first; start helper agents only if he says yes.
- **Honest:** never say something works unless you checked it; say what the tests proved and what only his eyes can
  confirm. Anything that goes through Windows or another program gets one real try first. In a discussion, any fact,
  number or assumption that could change his decision is checked or called a guess in the same sentence.
- **Save as you go:** this repo's handover files (START HERE, the current task, the history) are the memory. Update
  them and push as one quick save per round; a tablet chat gets its work onto `main` before it ends.
- **Ask first** before installing anything, changing a setting, creating a repo, or publishing or sending anything.
  Never delete permanently, never force-push, and keep secrets out of git.
<!-- working-with-ahmed:end -->
