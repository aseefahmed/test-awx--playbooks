# Install Pre-Commit Hook
One way to use the Ansible Best Practices checker is by integrating it with pre-commit, which is a framework for managing and maintaining Git hooks. Pre-commit allows you to define scripts that will be run automatically before committing code changes to your Git repository. You can use pre-commit to run the Ansible Best Practices checker on your Ansible code, ensuring that your code is checked for best practices every time you commit a change.

Install pre-commit on your local machine:

```
pip3 install pre-commit
```


and then enable pre-commit for your git repository by running the following command in the terminal:

```
pre-commit install
```

# Ansible Coding Standard
Make sure your Ansible playbooks and relevant YAML files meets the coding standards according to Ansible Lint. You can find some of the coding standard from the following confluence page:

https://barfoot.atlassian.net/wiki/spaces/IT/pages/397082625/Ansible+Coding+Standard
