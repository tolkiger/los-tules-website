# Kiro Configuration Directory

This directory contains configuration and steering files for the Kiro AI assistant.

## Steering Files

Steering files provide context and guidelines to Kiro when helping with this project.

### `steering/website-editing.md`
- **Inclusion**: Auto (always loaded)
- **Purpose**: Provides context about the website structure, file locations, and common editing tasks
- **Use**: Helps Kiro give accurate guidance when you ask about editing the website

### `steering/cicd-pipeline.md`
- **Inclusion**: Manual (loaded only when needed)
- **Purpose**: Contains instructions for CI/CD pipeline setup and usage
- **Use**: Reference this when working with GitHub Actions or automatic deployments

## How Steering Files Work

- **Auto inclusion**: Loaded automatically in every conversation
- **Manual inclusion**: Loaded only when you reference them with `#` in chat (e.g., `#cicd-pipeline`)

## For Users

You don't need to edit these files. They help Kiro understand your project better and provide more accurate assistance.

## For Developers

If you want to customize how Kiro helps with this project:
1. Edit existing steering files to add project-specific context
2. Create new steering files with front matter:
   ```markdown
   ---
   inclusion: auto  # or manual
   ---
   ```
3. Add project conventions, coding standards, or deployment procedures
