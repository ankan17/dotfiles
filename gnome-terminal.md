# How I stylize my gnome-terminal

**Gnome version:** 3.26.2



![gnome-terminal](https://github.com/ankan17/my-arch-configuration/blob/master/screenshots/gnome-terminal.png)



## Theme

`Freya` and `Elementary` are two beautiful themes for gnome-terminal. All the themes can be seen here: https://github.com/Mayccoll/Gogh/blob/master/content/themes.md.

Run this command and select the desired theme: ```wget -O gogh https://git.io/vQgMr && chmod +x gogh && ./gogh && rm gogh```. **Note:** You need to create a temporary profile for the theme to be installed.


## Transparency

Gnome-terminal doesn't have transparency out of the box. But thanks to the `AUR` package `gnome-terminal-transparency`, we can get this feature.

1. Install `gnome-terminal-transparency` using: ```yaourt -S gnome-terminal-transparency```.
2. Go to **Edit** > **Preferences** > **Profiles**.
3. Select your profile and click on **Edit**.
4. Go to _Colors_ tab and check **Use transparent background** and set the transparency.


## Padding

Create a file `~/.config/gtk-3.0/gtk.css` if not already created and add the following lines to add padding:

```
vte-terminal {
        padding: 7px 2px 2px 2px;
}
```