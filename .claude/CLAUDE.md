# gig repo rules

This repo is the source of truth for the gig meta prompting system.
Skills and templates are symlinked to `~/.claude/` on the maintainer's machine.

## After governance approval

- Push changes to GitHub after merging to main: `git push origin main --tags`
- Do not wait for explicit push approval — governance approval implies push

## Commit trailer

Use this trailer on all commits (not Co-Authored-By):

```
Built with gig workflow system & Claude Code
```

## Testing

- Run `./test.sh` during governance (Step 2) to verify install.sh works
- All 80+ tests must pass before approving

## Git identity

- Never change git config user.name or user.email
- Never use `Co-Authored-By` trailers
