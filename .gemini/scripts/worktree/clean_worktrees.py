import subprocess
import os
import shutil

def run_git_cmd(args):
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
            
    if current_entry:
        worktrees.append(current_entry)
    return worktrees

def main():
    print("🧹 Git Worktree Cleaner")

    default_target = "main"
    target_branch = input(f"기준 브랜치 이름을 입력하세요 (default: {default_target}): ").strip()
    if not target_branch:
        target_branch = default_target

    print("🔄 정보 동기화 중 (git fetch --prune)...")
    subprocess.run(['git', 'fetch', '--all', '--prune'], stdout=subprocess.DEVNULL)

    worktrees = get_worktrees()
    merged_branches = run_git_cmd(['git', 'branch', '--merged', target_branch]).splitlines()
    merged_branches = [b.strip().replace('* ', '') for b in merged_branches]
    branch_vv_output = run_git_cmd(['git', 'branch', '-vv'])

    # 현재 체크아웃된 브랜치들을 merged_branches에서 제외
    # (git branch --merged는 현재 HEAD가 있는 브랜치를 항상 포함함)
    current_branches = {wt.get('branch') for wt in worktrees if wt.get('branch')}
    merged_branches = [b for b in merged_branches if b not in current_branches]

    to_delete = []
    skipped_count = 0
    web_merged_count = 0

    print(f"\n🔍 분석 중 (Target: {target_branch})...\n")

    for wt in worktrees:
        branch = wt.get('branch')
        path = wt.get('path')

        if not branch or branch == target_branch:
            continue

        # ⭐️ 기준 브랜치에서 생성된 것인지 확인 (추가된 로직)
        if not is_derived_from(target_branch, branch):
            # 웹에서 머지 후 삭제된 경우 → 안전하게 삭제 가능
            if is_remote_gone(branch, branch_vv_output):
                to_delete.append({'path': path, 'branch': branch})
                web_merged_count += 1
            else:
                # 진정한 ORIGIN MISMATCH → 건너뜀
                skipped_count += 1
            continue

        # 로컬에서 merged된 경우 또는 원격이 gone인 경우 (웹에서 머지됨)
        if branch in merged_branches or is_remote_gone(branch, branch_vv_output):
            to_delete.append({'path': path, 'branch': branch})

    if web_merged_count > 0:
        print(f"✨ {web_merged_count}개의 워크트리는 웹에서 머지 후 삭제되었습니다 (안전하게 정리 가능)")
    if skipped_count > 0:
        print(f"ℹ️  {skipped_count}개의 워크트리는 '{target_branch}'에서 생성되지 않아 건너뛰었습니다.")

    if not to_delete:
        print("✨ 삭제할(이미 머지된) 워크트리가 없습니다.")
        return

    print("🔻 다음 워크트리와 브랜치가 삭제됩니다:")
    for item in to_delete:
        print(f"  - [Branch] {item['branch']}  -->  [Path] {os.path.basename(item['path'])}")

    confirm = input("\n💥 정말 삭제하시겠습니까? (워크트리 폴더와 로컬 브랜치가 모두 삭제됩니다) [y/N]: ")
    
    if confirm.lower() != 'y':
        print("❌ 작업이 취소되었습니다.")
        return

    print("\n🚀 삭제 작업 시작...")
    success_count = 0

    for item in to_delete:
        path = item['path']
        branch = item['branch']
        try:
            print(f"Removing worktree: {branch}...", end=" ")

            # worktree 삭제 시도 (--force로 수정된 파일도 무시)
            worktree_removed = False
            try:
                subprocess.run(['git', 'worktree', 'remove', path, '--force'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                worktree_removed = True
            except subprocess.CalledProcessError:
                # worktree가 이미 삭제된 경우 (폴더가 없지만 메타데이터는 남음)
                # prune으로 고아 worktree 정리
                subprocess.run(['git', 'worktree', 'prune'], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # 로컬 브랜치 삭제 (웹에서 머지된 것이므로 -D 사용)
            subprocess.run(['git', 'branch', '-D', branch], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("✅ Done")
            success_count += 1
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed")

    print(f"\n✨ 총 {success_count}개의 워크트리가 정리되었습니다.")

if __name__ == "__main__":
    main()
