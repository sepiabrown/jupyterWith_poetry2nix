# jupyterWith_poetry2nix
Have fun tinkering with `flake` + `poetry2nix` + `jupyterWith`!

Since `flake`, `poetry2nix`, `jupyterWith` are all experimental, use at your own risk.

The code is a mixture of tutorial example codes from [jupyterWith](https://github.com/tweag/jupyterWith) and [poetry2nix](https://github.com/nix-community/poetry2nix).

If you have any question regarding the implementation, contact me via bboxone@gmail.com

# How to use

0. Install latest [nix](https://nixos.org/download.html)
1. In terminal, `git clone`
2. In terminal, `cd jupyterWith_poetry2nix`
3. In terminal, `nix develop`
4. In terminal, `jupyter-lab --port <port-number-you-want>`
For example, if you want port 3333,
`jupyter-lab --port 3333`
5. In any browser (ex. chrome), `localhost:3333`
6. open ipynb file with kernel `Python3 - my-awesome-python-env`
