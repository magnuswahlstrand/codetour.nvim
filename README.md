
# CodeTour.nvim

A Neovim plugin for interactive code walkthroughs.

## 📦 Installation (Lazy.nvim)

```lua
{
    "magnuswahlstrand/codetour.nvim",
    config = function()
        require("codetour").setup()
    end
}
```

## 🚀 Usage

- `:CodeTourLoad path/to/tour.json` → Load a tour
- `:CodeTourNext` → Next step
- `:CodeTourPrev` → Previous step
- `:CodeTourExit` → Exit the tour
- `:CodeTourHideHint` → Hide the hint

## 🔧 Default Shortcuts

| Shortcut      | Action                |
|--------------|-----------------------|
| `<Leader>tn` | Next step              |
| `<Leader>tp` | Previous step          |
| `<Leader>te` | Exit tour              |
| `<Leader>th` | Hide hint              |

## 📄 Example Tour File (`demo.json`)

```json
{
    "steps": [
        {
            "file": "example.lua",
            "line": 5,
            "description": "This is where the main function starts."
        },
        {
            "file": "example.lua",
            "line": 12,
            "description": "This is the initialization of the config."
        }
    ]
}
```

## 💡 Configuration

You can override settings via:

```lua
require("codetour").setup({
    -- Your custom options here
})
```

