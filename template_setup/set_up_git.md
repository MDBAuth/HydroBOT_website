## Set up git

User settings

```         
git config --global user.name "John Doe"
git config --global user.email github_secret_email@users.noreply.github.com
```

Check

```         
git config --list
```

### SSH keys

Follow github instructions

1.  [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

    ```         
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
    ```

2.  [Add that to your github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

    -   LINUX

        ```         
        cat < ~/.ssh/id_rsa.pub
        ```

    -   WINDOWS

        ```         
        clip < ~/.ssh/id_rsa.pub
        ```

To load that SSH key into your shell (may not be necessary)

```         
eval "$(ssh-agent -s)"` and then `ssh-add ~/.ssh/NAME_OF_KEY
```
