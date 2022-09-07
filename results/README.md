# senzing-test-results

## Creating PDFs

1. Using `pandoc`.
   Example:

    ```console
    pandoc README.md \
      --from markdown-implicit_figures \
      --latex-engine=xelatex \
      --output README.pdf \
      --standalone \
      --table-of-contents \
      --toc-depth=5
    ```
