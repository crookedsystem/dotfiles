import subprocess
import os
import sys

def run_git_cmd(args):
    """Git 명령어를 실행하고 결과를 문자열로 반환"""
    try:
        result = subprocess.check_output(args, stderr=subprocess.DEVNULL).decode('utf-8').strip()
        return result
    except subprocess.CalledProcessError:
        return ""

def is_derived_from(target, branch):
    """
    브랜치가 target 브랜치에서 파생되었는지 확인
    (target에서 생성되었거나 target으로 머지되었는지 판단)
    """
    try:
        # target이 branch의 히스토리에 포함되는지 확인 (branch가 target으로부터 생성되었거나 업데이트됨)
        subprocess.check_output(
            ['git', 'merge-base', '--is-ancestor', target, branch],
            stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        pass

    try:
        # branch가 target의 히스토리에 포함되는지 확인 (branch가 target으로 머지됨)
        subprocess.check_output(
            ['git', 'merge-base', '--is-ancestor', branch, target],
            stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        return False

def is_remote_gone(branch, branch_vv_output):
    """
    원격 추적 브랜치가 gone인지 확인 (웹에서 머지 후 삭제된 경우)
    """
    return f"[origin/{branch}: gone]" in branch_vv_output

def get_worktrees():
    output = run_git_cmd(['git', 'worktree', 'list', '--porcelain'])
    worktrees = []
    current_entry = {}

    for line in output.splitlines():
        if line.startswith('worktree '):
            if current_entry:
                worktrees.append(current_entry)
            current_entry = {'path': line.split(' ', 1)[1]}
        elif line.startswith('branch '):
            ref = line.split(' ', 1)[1]
            current_entry['branch'] = ref.replace('refs/heads/', '')
        elif line.startswith('HEAD '):
            current_entry['head'] = line.split(' ', 1)[1]

    if current_entry:
        worktrees.append(current_entry)
    return worktrees

def main():
    default_target = "main"
    print("\n📊 Worktree Analyzer")
    target_branch = input(f"기준 브랜치 이름을 입력하세요 (default: {default_target}): ").strip()
    if not target_branch:
        target_branch = default_target

    print(f"\n🔄 Fetching & Pruning remote info...")
    subprocess.run(['git', 'fetch', '--all', '--prune'], stdout=subprocess.DEVNULL)

    print(f"\n=== Worktree Status Report (Target: {target_branch}) ===")

    current_head = run_git_cmd(['git', 'rev-parse', 'HEAD'])
    worktrees = get_worktrees()
    merged_branches = run_git_cmd(['git', 'branch', '--merged', target_branch]).splitlines()
    merged_branches = [b.strip().replace('* ', '') for b in merged_branches]
    branch_vv_output = run_git_cmd(['git', 'branch', '-vv'])

    for wt in worktrees:
        path = wt.get('path')
        branch = wt.get('branch')
        head = wt.get('head')

        if not branch:
            continue

        # 메인 워크트리(기준 브랜치 자체)는 스킵
        if branch == target_branch:
            print(f"[{branch:<30}] : 🎯 TARGET BRANCH (Base)")
            print(f"  └─ {path}")
            continue

        # 현재 체크아웃된 워크트리는 스킵
        if head == current_head:
            print(f"[{branch:<30}] : 🔄 CURRENT WORKTREE (Active now)")
            print(f"  └─ {path}")
            continue

        # ⭐️ 기준 브랜치에서 생성된 것인지 확인 (추가된 로직)
        if not is_derived_from(target_branch, branch):
            if is_remote_gone(branch, branch_vv_output):
                print(f"[{branch:<30}] : ✨ MERGED ON WEB (Remote deleted)")
            else:
                print(f"[{branch:<30}] : 🚫 ORIGIN MISMATCH (Not created from {target_branch})")
            print(f"  └─ {path}")
            continue

        # 기존 상태 판별 로직
        upstream = run_git_cmd(['git', 'rev-parse', '--abbrev-ref', f'{branch}@{{u}}'])
        gone_check = run_git_cmd(['git', 'branch', '-vv'])
        is_gone = f"[origin/{branch}: gone]" in gone_check if upstream else False
        # 원격이 gone인 경우 = 웹에서 머지되고 삭제됨 (이미 merged 상태)
        is_merged = branch in merged_branches or is_gone

        if is_merged:
            status = "✅ MERGED (Safe to delete)"
        elif is_gone:
            status = "⚠️  REMOTE GONE (Check commits)"
        elif not upstream:
            status = "🔒 LOCAL ONLY (Never pushed)"
        else:
            status = "🚧 NOT MERGED (Active development)"

        print(f"[{branch:<30}] : {status}")
        print(f"  └─ {path}")

if __name__ == "__main__"  :
    main()
