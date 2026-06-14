---
name: commit-skill
description: Conventional Commit Messages. 커밋 메시지 작성 및 PR 생성 지원. --only-commit 플래그로 커밋만 수행, 플래그 없으면 커밋 후 Push 및 PR 생성까지 진행.
---

## Flags

- `--only-commit`: 커밋만 수행 (Push/PR 생성 없음)
- (기본): 커밋 → Push → PR 생성까지 진행 → [references/pr-guide.md](references/pr-guide.md) 참조

## Commit Message Formats

### Default

<pre>
<b>&lt;type&gt;</b>(<b>&lt;optional scope&gt;</b>): <b>&lt;description&gt;</b>
<sub>empty separator line</sub>
<b>&lt;optional body&gt;</b>
<sub>empty separator line</sub>
<b>&lt;optional footer&gt;</b>
</pre>

### Merge Commit

<pre>
Merge branch '<b>&lt;branch name&gt;</b>'
</pre>

### Revert Commit

<pre>
Revert "<b>&lt;reverted commit subject line&gt;</b>"
</pre>

### Initial Commit

```
chore: init
```

### Types

* API or UI relevant changes
  * "feat" Commits, that add or remove a new feature to the API or UI
  * "fix" Commits, that fix an API or UI bug of a preceded "feat" commit
  * "modify" Commits, that change existing functionality or behavior
* "refactor" Commits, that rewrite/restructure your code, however do not change any API or UI behaviour
  * "perf" Commits are special "refactor" commits, that improve performance
* "style" Commits, that do not affect the meaning (white-space, formatting, missing semi-colons, etc)
* "test" Commits, that add missing tests or correcting existing tests
* "docs" Commits, that affect documentation only
* "build" Commits, that affect build components like build tool, ci pipeline, dependencies, project version, ...
* "ops" Commits, that affect operational components like infrastructure, deployment, backup, recovery, ...
* "chore" Miscellaneous commits e.g. modifying ".gitignore"

### Scopes

The "scope" provides additional contextual information.

* Is an **optional** part of the format
* Allowed Scopes depend on the specific project
* Don't use issue identifiers as scopes

### Breaking Changes Indicator

Breaking changes should be indicated by adding "!" before ":" in the subject line e.g. "feat(api)!: remove status endpoint"

* Is an **optional** part of the format
* Breaking changes **must** be described in the commit footer section

### Description

* It is a **mandatory** part of the format
* Use the imperative, present tense: "change" not "changed" nor "changes"
* Don't capitalize the first letter
* No dot (".") at the end

### Body

* Is an **optional** part of the format
* Use the imperative, present tense
* This is the place to mention issue identifiers and their relations

### Footer

* Is an **optional** part of the format
* **optionally** reference an issue by its id.
* **Breaking Changes** should start with the word "BREAKING CHANGE:" followed by space or two newlines.

### Examples

```
feat: add email notifications on new direct messages
```

```
feat(shopping cart): add the amazing button
```

```
feat!: remove ticket list endpoint

refers to JIRA-1337

BREAKING CHANGE: ticket endpoints no longer supports list all entities.
```

```
fix(api): fix wrong calculation of request body checksum
```

```
perf: decrease memory footprint for determine uniqe visitors by using HyperLogLog
```

```
refactor: implement fibonacci number calculation as recursion
```

---

## 커밋 작성 지침

### 중요 사항

* **모든 커밋 메시지는 한국어로 작성**
* Claude Code 워터마크를 **절대** 포함하지 않음 (Co-Authored-By: Claude 등 제거)
* git diff를 통해 변경 사항을 충분히 분석하고, 논리적으로 커밋을 분리
* 각 커밋은 하나의 의미 있는 변경 단위로 구성

### 커밋 전 체크리스트

1. `git diff`로 모든 변경 사항 확인
2. **절대 커밋하지 말아야 할 파일 확인**
   * `.claude/` (디렉토리 전체), `CLAUDE.local.md`, `GEMINI.md`, `AGENTS.md` 등 AI 설정 파일
   * 위 파일들이 staging area에 포함되어 있다면 반드시 제거
3. 관련된 변경 사항끼리 그룹핑하여 커밋 단위 결정
4. **문서 변경사항 확인** → `docs:` 접두어 사용
5. 커밋 메시지는 변경의 "이유"와 "무엇"을 명확히 설명
