#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_succ() { echo -e "${GREEN}✅ $1${NC}"; }
log_fail() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo "ℹ️  $1"; }

# Cleanup function
cleanup() {
    log_info "クリーンアップ中..."
    git checkout main >/dev/null 2>&1
    if [ -f .current_exp ]; then
        EXP_ID=$(cat .current_exp)
        if git show-ref --verify --quiet refs/heads/exp/$EXP_ID; then
            git branch -D exp/$EXP_ID >/dev/null 2>&1
        fi
        rm -f .current_exp
    fi
    # Remove dummy tracked file if exists
    rm -f dummy_change
    git restore . >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
}

setup_env() {
    # Ensure trials dir exists
    mkdir -p trials
}

# --- Test Cases ---

test_failure_no_active_exp() {
    log_info "テスト: 失敗系 - 実行中の実験なし"
    cleanup
    
    # Try running without active experiment
    if ./scripts/run_experiment.sh "Should fail" >/dev/null 2>&1; then
        log_fail "run_experiment.sh は実行中の実験がない場合失敗すべき"
        return 1
    fi
    
    if ./scripts/cycle.sh close "Should fail" >/dev/null 2>&1; then
        log_fail "cycle.sh close は実行中の実験がない場合失敗すべき"
        return 1
    fi
    
    log_succ "実行中の実験なしテスト合格"
    return 0
}

test_failure_dirty_start() {
    log_info "テスト: 失敗系 - 変更ありでの開始"
    cleanup
    
    # Make repo dirty
    touch dummy_change
    
    if ./scripts/cycle.sh start "Should fail" >/dev/null 2>&1; then
        log_fail "リポジトリに変更がある場合、開始は失敗すべき"
        rm dummy_change
        return 1
    fi
    
    rm dummy_change
    log_succ "変更ありでの開始テスト合格"
    return 0
}

test_failure_dirty_run() {
    log_info "テスト: 失敗系 - 変更ありでの実行"
    cleanup
    
    # Start valid experiment
    ./scripts/cycle.sh start "Dirty Run Test" >/dev/null 2>&1
    
    # Make repo dirty
    touch dummy_change
    
    if ./scripts/run_experiment.sh "Should fail" >/dev/null 2>&1; then
        log_fail "リポジトリに変更がある場合、実行は失敗すべき"
        cleanup
        return 1
    fi
    
    cleanup
    log_succ "変更ありでの実行テスト合格"
    return 0
}

test_success_path() {
    log_info "テスト: 成功パス"
    cleanup
    
    # 1. Start
    if ! ./scripts/cycle.sh start "Success Path Test"; then
        log_fail "開始失敗"
        return 1
    fi
    EXP_ID=$(cat .current_exp)
    log_info "開始しました $EXP_ID"
    
    # 2. Mock Spec (simulate user action)
    mkdir -p "trials/$EXP_ID"
    SPEC_FILE="trials/$EXP_ID/spec.md"
    echo "Mock Spec" > "$SPEC_FILE"
    
    # 3. Commit (needed for run)
    git add .
    git commit -m "Add mocking spec" >/dev/null 2>&1
    
    # 4. Run
    if ! ./scripts/run_experiment.sh "Test Run"; then
        log_fail "実行失敗"
        cleanup
        return 1
    fi
    
    # Verify artifacts
    if [ ! -f "reports/metrics.json" ]; then
        log_fail "成果物 reports/metrics.json がありません"
        cleanup
        return 1
    fi
    
    if [ ! -f "trials/$EXP_ID/reports/metrics.json" ]; then
        log_fail "Sidecar成果物がありません"
        cleanup
        return 1
    fi
    
    # 5. Close
    if ! ./scripts/cycle.sh close "Test Success"; then
        log_fail "終了失敗"
        cleanup
        return 1
    fi
    
    # Verify cleanup
    if [ -f ".current_exp" ]; then
        log_fail "終了後に .current_exp が削除されているべき"
        return 1
    fi
    
    log_succ "成功パステスト合格"
    return 0
}

# --- Main ---

# Safety check
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ リポジトリに変更があります。テストを実行する前にコミットまたはスタッシュしてください。"
    exit 1
fi

setup_env

FAILURES=0

test_failure_no_active_exp || ((FAILURES++))
test_failure_dirty_start || ((FAILURES++))
test_failure_dirty_run || ((FAILURES++))
test_success_path || ((FAILURES++))

if [ $FAILURES -eq 0 ]; then
    echo -e "\n${GREEN}全テスト合格！${NC}"
    exit 0
else
    echo -e "\n${RED}$FAILURES 件の検証に失敗しました。${NC}"
    exit 1
fi
