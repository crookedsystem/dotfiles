## 파일 작성 규칙

### 한글/이모지 포함 파일 생성 시

- 인코딩은 항상 UTF-8
- Write/Edit 도구 대신 Bash heredoc 사용:

```bash
cat << 'EOF' > filename.md
한글과 이모지가 포함된 내용
EOF
```

- 'EOF'를 따옴표로 감싸서 변수 확장 방지
