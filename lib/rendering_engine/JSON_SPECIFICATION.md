# Certificate Maker Rendering Engine JSON Specification & Schema Documentation

This document covers all parameters, schema definitions, layer types, visual styling models, coordinates, transformations, and fallback behaviors supported by the **Custom Rendering Engine** in the Certificate Maker application.

---

## 1. Top-Level Scene Document Structure

A certificate scene JSON represents a `SceneDocument` that loads into the rendering engine:

```json
{
  "schemaVersion": "2.1.0",
  "minEngineVersion": "3.5.0",
  "compatibilityMode": "graceful_degrade",
  "metadata": {
    "id": "certificate_unique_id",
    "name": "Academic Excellence Certificate",
    "category": "Achievement",
    "author": "Designer"
  },
  "validation": {},
  "canvas": { ... },
  "assets": { ... },
  "theme": { ... },
  "dividers": [ ... ],
  "scene": {
    "layers": [ ... ]
  }
}
```

### Top-Level Properties

| Parameter | Type | Required | Default | Explanation |
| :--- | :--- | :--- | :--- | :--- |
| `schemaVersion` | `string` | No | `"2.1.0"` | Schema specification version. |
| `minEngineVersion`| `string` | No | `"3.5.0"` | Minimum compatible engine version. |
| `compatibilityMode`| `string`| No | `"graceful_degrade"` | Fallback strategy (`graceful_degrade` or `strict`). |
| `metadata` | `object` | No | `{}` | Key-value dictionary containing template info (id, name, category, tags, author, etc.). |
| `validation` | `object` | No | `{}` | Optional constraint and integrity rules. |
| `canvas` | `object` | **Yes** | `{}` | Virtual canvas coordinate space, aspect ratio, and layout spacing. |
| `assets` | `object` | No | `{}` | Map of registered media and font assets keyed by `assetId`. |
| `theme` | `object` | No | `{}` | Global theme definitions (such as background styling). |
| `dividers` | `array` | No | `[]` | Dynamic collage dividers (used for multi-photo / split templates). |
| `scene` | `object` | **Yes** | `{"layers": []}` | Contains the array of visual `layers`. |

---

## 2. Canvas Configuration (`canvas`)

The canvas establishes the virtual resolution coordinate system. All layer bounding boxes are computed relative to this virtual space (which is dynamically scaled to fit device screens or export resolutions without raster degradation).

```json
"canvas": {
  "virtualSize": {
    "width": 1000.0,
    "height": 700.0
  },
  "defaultAspectRatio": "10:7",
  "supportedAspectRatios": [
    {
      "id": "10:7",
      "label": "10:7 (Landscape)",
      "isDefault": true
    },
    {
      "id": "1:1",
      "label": "Square",
      "isDefault": false
    }
  ],
  "layoutSpacing": {
    "outer": 0.0,
    "inner": 0.0
  }
}
```

### Canvas Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `virtualSize.width` (or `width`) | `number` | `1000.0` | Total virtual width. |
| `virtualSize.height` (or `height`) | `number` | `1000.0` | Total virtual height. |
| `defaultAspectRatio` | `string` | `"1:1"` | Default aspect ratio identifier (e.g. `"1:1"`, `"4:3"`, `"16:9"`). |
| `supportedAspectRatios` | `array` | `[]` | List of supported aspect ratio presets. Each has `id`, `label`, and `isDefault`. |
| `layoutSpacing.outer` | `number` | `0.0` | Outer margin around the entire canvas. |
| `layoutSpacing.inner` | `number` | `0.0` | Inner gutter between divided cells or frames. |

---

## 3. Assets Dictionary (`assets`)

Defines all external resources (local asset paths, disk files, or network URLs) needed to render the certificate.

```json
"assets": {
  "background_image": {
    "type": "image",
    "src": "assets/Final_Certificates/Achievement/1/Colorful Achievement.png",
    "fallbackSrc": null
  },
  "gold_badge": {
    "type": "image",
    "src": "assets/stickers/badge_gold.png"
  },
  "LibreBodoni": {
    "type": "font",
    "src": "assets/fonts/LibreBodoni-VariableFont_wght.ttf"
  }
}
```

### Asset Parameters

| Parameter | Type | Required | Values / Formats |
| :--- | :--- | :--- | :--- |
| `type` | `string` | **Yes** | `"image"`, `"svg"`, `"font"`, `"video"` |
| `src` | `string` | **Yes** | Local Flutter bundle path (e.g., `assets/...`), file path, or URL. |
| `fallbackSrc` | `string` | No | Secondary backup path if `src` fails to resolve. |

---

## 4. Theme & Background (`theme.background`)

Defines the default background for the canvas.

```json
"theme": {
  "background": {
    "type": "color",
    "color": 4294967295,
    "imagePath": null,
    "opacity": 1.0,
    "blur": 0.0,
    "brightness": 1.0,
    "saturation": 1.0,
    "contrast": 1.0
  }
}
```

### Background Parameters

- **`type`** (`string`): `"color"`, `"gradient"`, or `"image"`.
- **`color`** (`integer` or hex): Color ARGB integer (e.g., `4294967295` for `#FFFFFFFF`) or hex string.
- **`gradient`** (`object`):
  - `type`: `"linear"`, `"radial"`, or `"sweep"`
  - `colors`: Array of ARGB integers/hex strings (e.g., `["#FFD700", "#FFA500"]`)
  - `stops`: Array of normalized position stops `[0.0, 1.0]`
  - `begin` / `end`: Alignment points `{"x": 0.0, "y": 0.0}`, `{"x": 1.0, "y": 1.0}`
- **`imagePath`** (`string`): Path to the background image.
- **`opacity`** (`number`): `0.0` to `1.0`.
- **`blur`** (`number`): Blur sigma radius.
- **`brightness`** / **`saturation`** / **`contrast`** (`number`): Color adjustment factors (default: `1.0`).

---

## 5. Common Layer Properties (Inherited by All Scene Nodes)

Every layer inside `scene.layers` shares these base properties:

```json
{
  "id": "unique_layer_id",
  "displayName": "Student Name",
  "type": "text",
  "renderPass": "text",
  "zIndex": 10,
  "state": {
    "visible": true,
    "locked": false
  },
  "interaction": {
    "selectable": true,
    "movable": true,
    "editable": true,
    "hitPadding": 0.0
  },
  "bounds": {
    "x": 100.0,
    "y": 250.0,
    "width": 800.0,
    "height": 60.0
  },
  "transform": {
    "rotation": 0.0,
    "pivot": { "x": 0.5, "y": 0.5 },
    "skew": { "x": 0.0, "y": 0.0 },
    "flipX": false,
    "flipY": false
  }
}
```

### Common Node Fields Explained

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | Unique layer identifier. Used to track selections and bindings. |
| `displayName`| `string` | Human-readable name displayed in layer managers and editor panels. |
| `type` | `string` | Layer discriminator: `"text"`, `"frame"`, `"sticker"`, `"svg"`, `"shape"`, or `"group"`. |
| `renderPass` | `string` | Render execution pass: `"background"`, `"fill"`, `"content"`, `"text"`, `"sticker"`, `"stroke"`, `"overlay"`. |
| `zIndex` | `integer` | Stacking order. Higher z-index renders on top. |
| `state.visible` | `boolean` | Whether the node is visible (`true`) or hidden (`false`). |
| `state.locked` | `boolean` | When `true`, user cannot move or edit the layer on canvas. |
| `interaction.selectable`| `boolean` | Can the user tap to select this element in the editor? |
| `interaction.movable` | `boolean` | Can the user drag and reposition this layer? |
| `interaction.editable` | `boolean` | Can the content / properties be modified? |
| `interaction.hitPadding`| `number` | Extra touch target expansion around the layer bounding box. |
| `bounds.x` | `number` | Left position in virtual canvas coordinates. |
| `bounds.y` | `number` | Top position in virtual canvas coordinates. |
| `bounds.width` | `number` | Layer width in virtual units. |
| `bounds.height` | `number` | Layer height in virtual units. |
| `transform.rotation` | `number` | Rotation angle in radians (e.g. `0.0`, `1.5708` for 90°, `3.14159` for 180°). |
| `transform.pivot` | `object` | Relative rotation pivot `{"x": 0.5, "y": 0.5}` (`0.5, 0.5` is exact center). |
| `transform.skew` | `object` | Horizontal and vertical shear factor `{"x": 0.0, "y": 0.0}`. |
| `transform.flipX` | `boolean` | Flip horizontally. |
| `transform.flipY` | `boolean` | Flip vertically. |

---

## 6. Layer Types

---

### 6.1. Text Layer (`"type": "text"`)

Renders typography with support for bending/curving, custom shadows, letter spacing, word spacing, and line height.

> **Note on Content Structure:** Properties can be placed directly on the root of the node OR inside a `"content": { ... }` block. Both are supported.

```json
{
  "id": "recipient_name",
  "displayName": "Recipient Name",
  "type": "text",
  "renderPass": "text",
  "zIndex": 20,
  "state": { "visible": true, "locked": false },
  "interaction": { "selectable": true, "movable": true, "editable": true },
  "bounds": { "x": 100, "y": 250, "width": 800, "height": 60 },
  "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
  "content": {
    "text": "JOHN DOE",
    "fontFamily": "LibreBodoni",
    "fontSize": 48.0,
    "color": "#1A237E",
    "align": "center",
    "fontWeight": "bold",
    "fontStyle": "normal",
    "decoration": "none",
    "opacity": 1.0,
    "letterSpacing": 2.0,
    "wordSpacing": 4.0,
    "lineHeight": 1.2,
    "textBend": 0.0,
    "textBendRadius": 300.0,
    "shadow": {
      "enabled": true,
      "color": "#40000000",
      "opacity": 0.4,
      "offset": { "x": 2.0, "y": 3.0 },
      "blurRadius": 4.0,
      "spreadRadius": 0.0
    }
  }
}
```

#### Text Parameters

| Parameter | Type | Default | Allowed Values / Explanations |
| :--- | :--- | :--- | :--- |
| `text` | `string` | `""` | The display string. |
| `fontFamily` | `string` | `"System"` | Font family name (e.g. `"System"`, `"LibreBodoni"`, `"LoveYaLikeASister"`, `"OoohBaby"`, etc.). |
| `fontSize` | `number` | `14.0` | Virtual font size. |
| `color` | `string` | `"#FFFFFFFF"` | Hex color string (`"#RRGGBB"` or `"#AARRGGBB"`). |
| `align` (or `textAlign`) | `string` | `"left"` | `"left"`, `"center"`, `"right"`, `"justify"`. |
| `fontWeight` | `string` | `"normal"` | `"normal"`, `"bold"`, `"100"` through `"900"`, `"w100"` through `"w900"`. |
| `fontStyle` | `string` | `"normal"` | `"normal"`, `"italic"`. |
| `decoration` | `string` | `"none"` | `"none"`, `"underline"`, `"lineThrough"`, `"overline"`. |
| `opacity` | `number` | `1.0` | `0.0` (fully transparent) to `1.0` (opaque). |
| `letterSpacing` | `number` | `0.0` | Extra horizontal space between individual characters. |
| `wordSpacing` | `number` | `0.0` | Extra spacing between words. |
| `lineHeight` | `number` | `null` | Multiplier for line height (e.g., `1.2`, `1.5`). If omitted, natural font height is used. |
| `textBend` | `number` | `0.0` | Curvature percentage from `-100.0` to `100.0`. Positive bends upwards/arch, negative bends downwards. Set `0.0` for straight text. |
| `textBendRadius` | `number` | `300.0` | The arc radius for bent text. |
| `shadow` | `object` | `{}` | Text shadow object (see [Styling Models](#7-styling-models)). |

---

### 6.2. Frame Layer (`"type": "frame"`)

Frames serve as slots or containers for background plates, certificate borders, photo holders, and clipped imagery.

```json
{
  "id": "background_frame",
  "displayName": "Certificate Background",
  "type": "frame",
  "renderPass": "content",
  "zIndex": 0,
  "state": { "visible": true, "locked": true },
  "interaction": { "selectable": false, "movable": false, "editable": false },
  "bounds": { "x": 0, "y": 0, "width": 1000, "height": 700 },
  "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
  "placeholder": {
    "assetId": "background_image",
    "mediaType": "image"
  },
  "mask": {
    "type": "rect"
  },
  "style": {
    "fill": {
      "type": "solid",
      "color": "#FFFFFF"
    },
    "border": {
      "width": 0.0
    }
  },
  "contentOffsetX": 0.0,
  "contentOffsetY": 0.0,
  "contentScale": 1.0,
  "contentRotation": 0.0,
  "contentFlipX": false,
  "padding": 0.0
}
```

#### Frame Parameters

| Parameter | Type | Default | Explanation |
| :--- | :--- | :--- | :--- |
| `placeholder.assetId`| `string` | `""` | Key into the top-level `"assets"` map pointing to the image to render inside this frame. |
| `placeholder.mediaType`| `string`| `"image"` | `"image"`, `"video"`, or `"vector"`. |
| `mask` | `object` | `{"type": "rect"}`| The clipping geometry for this frame (see [Masks Specification](#8-cell-masks-clipping)). |
| `style` | `object` | `{}` | Visual styling (background fill, border, shadows). |
| `contentOffsetX` / `Y`| `number` | `0.0` | Pan offset of the image inside the frame. |
| `contentScale` | `number` | `1.0` | Zoom/scale multiplier for the framed content. |
| `contentRotation` | `number` | `0.0` | Rotation angle of the inner image in radians. |
| `contentFlipX` | `boolean` | `false` | Mirror flip the image horizontally. |
| `padding` | `number` | `0.0` | Internal inset padding before content is drawn. |

---

### 6.3. Sticker / Badge Layer (`"type": "sticker"`)

Used for certificate badges, gold seals, ribbons, medals, and decorative stamps.

```json
{
  "id": "gold_seal",
  "displayName": "Gold Seal Badge",
  "type": "sticker",
  "renderPass": "sticker",
  "zIndex": 15,
  "state": { "visible": true, "locked": false },
  "interaction": { "selectable": true, "movable": true, "editable": true },
  "bounds": { "x": 800, "y": 500, "width": 120, "height": 120 },
  "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
  "assetId": "gold_badge",
  "mediaType": "image",
  "cropLeft": 0.0,
  "cropTop": 0.0,
  "cropRight": 0.0,
  "cropBottom": 0.0,
  "shape": "circle",
  "cornerRadius": 0.0,
  "imageScale": 1.0,
  "imageOffsetX": 0.0,
  "imageOffsetY": 0.0,
  "style": {
    "shadow": {
      "enabled": true,
      "color": "#4D000000",
      "offset": { "x": 3.0, "y": 4.0 },
      "blurRadius": 6.0
    }
  }
}
```

#### Sticker Parameters

| Parameter | Type | Default | Explanation |
| :--- | :--- | :--- | :--- |
| `assetId` | `string` | `""` | Key into the top-level `"assets"` map. |
| `mediaType` | `string` | `"image"` | Media type (`"image"` or `"svg"`). |
| `cropLeft` / `Top` / `Right` / `Bottom` | `number` | `0.0` | Normalized crop margins `[0.0 - 1.0]`. |
| `shape` | `string` | `null` | Optional clipping shape: `"circle"`, `"rounded_rect"`, or `null`. |
| `cornerRadius` | `number` | `0.0` | Corner radius if `shape` is `"rounded_rect"`. |
| `imageScale` | `number` | `1.0` | Scale adjustment factor. |
| `imageOffsetX` / `Y` | `number` | `0.0` | Alignment shift. |
| `style` | `object` | `null` | Optional border, shadow, or blend effects. |

---

### 6.4. Shape Layer (`"type": "shape"`)

Vector primitive shapes generated programmatically by the geometry pipeline.

```json
{
  "id": "divider_line",
  "displayName": "Golden Divider",
  "type": "shape",
  "renderPass": "content",
  "zIndex": 5,
  "state": { "visible": true, "locked": false },
  "interaction": { "selectable": true, "movable": true, "editable": true },
  "bounds": { "x": 200, "y": 320, "width": 600, "height": 4 },
  "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
  "generatorId": "rect",
  "parameters": {
    "cornerRadius": 2.0
  },
  "style": {
    "fill": {
      "type": "linear",
      "colors": ["#00B8860B", "#FFD700", "#00B8860B"],
      "stops": [0.0, 0.5, 1.0],
      "begin": { "x": 0.0, "y": 0.5 },
      "end": { "x": 1.0, "y": 0.5 }
    }
  }
}
```

#### Supported Generators (`generatorId`)

- `"rect"` / `"rectangle"`: Standard rectangle (optional `cornerRadius`).
- `"circle"`: Circle / oval filling bounds.
- `"ellipse"`: Ellipse.
- `"polygon"`: Multi-sided polygon (parameters: `sides` e.g. `5`, `6`, `8`, or `points`).
- `"star"`: Multi-point star (parameters: `points`, `innerRadiusRatio`).
- `"heart"`: Heart shape.
- `"arrow"`: Directional arrow (parameters: `tailWidth`, `headLength`).
- `"cloud"` / `"blob"`: Organic shapes.

---

### 6.5. SVG Vector Layer (`"type": "svg"`)

Renders arbitrary SVG path data with fills, borders, and gradients.

```json
{
  "id": "vector_flourish",
  "displayName": "Corner Flourish",
  "type": "svg",
  "renderPass": "content",
  "zIndex": 6,
  "state": { "visible": true, "locked": false },
  "interaction": { "selectable": true, "movable": true, "editable": true },
  "bounds": { "x": 50, "y": 50, "width": 100, "height": 100 },
  "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
  "geometry": {
    "pathData": "M 0,0 L 100,0 L 100,20 C 60,20 20,60 20,100 L 0,100 Z"
  },
  "style": {
    "fill": {
      "type": "solid",
      "color": "#D4AF37"
    }
  }
}
```

#### SVG Parameters

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `geometry.pathData` (or `pathData`) | `string` | Standard SVG path string (`M`, `L`, `C`, `S`, `Q`, `A`, `Z` commands). |
| `style` | `object` | Fill, border stroke, and shadow styling applied to the path. |

---

## 7. Styling Models (`style`)

The `NodeStyle` object configures fills, strokes, drop shadows, glows, and blend modes:

```json
"style": {
  "fill": { ... },
  "border": { ... },
  "shadow": { ... },
  "innerShadow": { ... },
  "glow": { ... },
  "effects": { ... }
}
```

### 7.1. Fill Style (`fill`)

Can be a simple color string (e.g. `"fill": "#FFFFFF"`) or a full fill object:

```json
"fill": {
  "type": "linear",
  "color": "#FFD700",
  "opacity": 1.0,
  "colors": ["#BF953F", "#FCF6BA", "#B38728", "#FBF5B7", "#AA771C"],
  "stops": [0.0, 0.25, 0.5, 0.75, 1.0],
  "begin": { "x": 0.0, "y": 0.0 },
  "end": { "x": 1.0, "y": 1.0 },
  "center": { "x": 0.5, "y": 0.5 },
  "radius": 0.5
}
```

- **`type`**: `"solid"`, `"linear"`, `"radial"`, `"sweep"`.
- **`color`**: Hex color string for solid fill.
- **`colors`**: Array of hex color strings for gradients.
- **`stops`**: Array of double positions `[0.0 to 1.0]`.
- **`begin` / `end`**: Relative coordinates for linear gradients (`0.0, 0.0` is top-left, `1.0, 1.0` is bottom-right).
- **`center`**: Relative center point for radial and sweep gradients.
- **`radius`**: Relative radius for radial gradients (default: `0.5`).
- **`opacity`**: Opacity multiplier `[0.0 - 1.0]`.

### 7.2. Border / Stroke Style (`border`)

```json
"border": {
  "width": 2.0,
  "alignment": "inside",
  "style": "solid",
  "color": "#D4AF37",
  "opacity": 1.0,
  "strokeJoin": "round",
  "strokeCap": "round",
  "left": null,
  "top": null,
  "right": null,
  "bottom": null
}
```

- **`width`**: Stroke width in virtual units.
- **`alignment`**: `"inside"`, `"center"`, `"outside"`.
- **`style`**: `"solid"`, `"dashed"`, `"dotted"`.
- **`color`**: Hex color string.
- **`fill`**: Optional gradient fill object for metallic/gradient borders.
- **`strokeJoin`**: `"miter"`, `"round"`, `"bevel"`.
- **`strokeCap`**: `"butt"`, `"round"`, `"square"`.
- **`left` / `top` / `right` / `bottom`**: Optional asymmetric borders for boxes.

### 7.3. Shadow Style (`shadow`)

```json
"shadow": {
  "enabled": true,
  "color": "#40000000",
  "opacity": 0.3,
  "offset": { "x": 4.0, "y": 4.0 },
  "blurRadius": 8.0,
  "spreadRadius": 0.0
}
```

- **`enabled`** (or `visible`): `true` or `false`.
- **`color`**: Hex color of shadow.
- **`offset`**: Shift in virtual pixels `{"x": 4.0, "y": 4.0}`.
- **`blurRadius`**: Gaussian blur radius.
- **`spreadRadius`**: Expansion radius.

### 7.4. Glow Style (`glow`)

```json
"glow": {
  "enabled": true,
  "color": "#FFFFD700",
  "radius": 12.0,
  "opacity": 0.8
}
```

### 7.5. Effects Style (`effects`)

```json
"effects": {
  "opacity": 1.0,
  "blendMode": "normal"
}
```

- **`blendMode`**: `"normal"`, `"multiply"`, `"screen"`, `"overlay"`, `"darken"`, `"lighten"`, `"softLight"`, `"hardLight"`.

---

## 8. Cell Masks & Clipping (`mask`)

Frames can clip their content using various geometry masks:

### Rect Mask
```json
"mask": { "type": "rect" }
```

### Rounded Rectangle Mask
```json
"mask": {
  "type": "rounded_rect",
  "cornerRadius": 16.0
}
```

### Circle Mask
```json
"mask": { "type": "circle" }
```

### Polygon Mask (Normalized coordinates between `0.0` and `1.0`)
```json
"mask": {
  "type": "polygon",
  "points": [
    { "x": 0.5, "y": 0.0 },
    { "x": 1.0, "y": 0.5 },
    { "x": 0.5, "y": 1.0 },
    { "x": 0.0, "y": 0.5 }
  ]
}
```

### SVG Path Mask
```json
"mask": {
  "type": "svg",
  "svgPathData": "M 0,0 L 100,0 L 50,100 Z"
}
```

### Boolean Mask (CSG Compound Clipping)
```json
"mask": {
  "type": "boolean",
  "operation": "intersect",
  "children": [
    { "type": "circle" },
    { "type": "rounded_rect", "cornerRadius": 10.0 }
  ]
}
```

---

## 9. Complete Working Certificate JSON Example

Below is a complete, production-ready certificate template showing how all elements fit together:

```json
{
  "schemaVersion": "2.1.0",
  "minEngineVersion": "3.5.0",
  "compatibilityMode": "graceful_degrade",
  "metadata": {
    "id": "certificate_gold_achievement",
    "name": "Classic Gold Achievement",
    "category": "Achievement"
  },
  "canvas": {
    "virtualSize": {
      "width": 1000,
      "height": 700
    },
    "defaultAspectRatio": "10:7",
    "supportedAspectRatios": [
      { "id": "10:7", "label": "Landscape", "isDefault": true }
    ],
    "layoutSpacing": {
      "outer": 0.0,
      "inner": 0.0
    }
  },
  "assets": {
    "cert_bg": {
      "type": "image",
      "src": "assets/Final_Certificates/Achievement/1/Colorful Achievement.png"
    },
    "gold_badge": {
      "type": "image",
      "src": "assets/stickers/badge.png"
    },
    "LibreBodoni": {
      "type": "font",
      "src": "assets/fonts/LibreBodoni-VariableFont_wght.ttf"
    }
  },
  "scene": {
    "layers": [
      {
        "id": "background",
        "displayName": "Certificate Background",
        "type": "frame",
        "renderPass": "content",
        "zIndex": 0,
        "state": { "visible": true, "locked": true },
        "interaction": { "selectable": false, "movable": false, "editable": false },
        "bounds": { "x": 0, "y": 0, "width": 1000, "height": 700 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "placeholder": { "assetId": "cert_bg", "mediaType": "image" },
        "mask": { "type": "rect" },
        "style": {}
      },
      {
        "id": "cert_header",
        "displayName": "Certificate Header",
        "type": "text",
        "renderPass": "text",
        "zIndex": 10,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 100, "y": 100, "width": 800, "height": 45 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "content": {
          "text": "CERTIFICATE OF ACHIEVEMENT",
          "fontFamily": "LibreBodoni",
          "fontSize": 32.0,
          "color": "#B8860B",
          "align": "center",
          "fontWeight": "bold",
          "letterSpacing": 3.0
        }
      },
      {
        "id": "presentation_text",
        "displayName": "Presentation Text",
        "type": "text",
        "renderPass": "text",
        "zIndex": 11,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 100, "y": 170, "width": 800, "height": 25 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "content": {
          "text": "THIS IS PROUDLY PRESENTED TO",
          "fontFamily": "System",
          "fontSize": 14.0,
          "color": "#555555",
          "align": "center",
          "letterSpacing": 2.0
        }
      },
      {
        "id": "recipient_name",
        "displayName": "Recipient Name",
        "type": "text",
        "renderPass": "text",
        "zIndex": 12,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 100, "y": 230, "width": 800, "height": 60 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "content": {
          "text": "ALEXANDER SMITH",
          "fontFamily": "LibreBodoni",
          "fontSize": 46.0,
          "color": "#111111",
          "align": "center",
          "fontWeight": "bold",
          "decoration": "underline"
        }
      },
      {
        "id": "award_description",
        "displayName": "Award Description",
        "type": "text",
        "renderPass": "text",
        "zIndex": 13,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 150, "y": 320, "width": 700, "height": 60 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "content": {
          "text": "For outstanding performance, dedication, and exemplary achievements throughout the 2026 Academic Year.",
          "fontFamily": "System",
          "fontSize": 16.0,
          "color": "#444444",
          "align": "center",
          "lineHeight": 1.4
        }
      },
      {
        "id": "seal_badge",
        "displayName": "Gold Medal Seal",
        "type": "sticker",
        "renderPass": "sticker",
        "zIndex": 20,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 440, "y": 420, "width": 120, "height": 120 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "assetId": "gold_badge",
        "mediaType": "image",
        "shape": "circle",
        "style": {
          "shadow": {
            "enabled": true,
            "color": "#33000000",
            "offset": { "x": 2, "y": 4 },
            "blurRadius": 6
          }
        }
      },
      {
        "id": "signature_line",
        "displayName": "Signature Line",
        "type": "shape",
        "renderPass": "content",
        "zIndex": 14,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 650, "y": 570, "width": 200, "height": 2 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "generatorId": "rect",
        "parameters": {},
        "style": {
          "fill": {
            "type": "solid",
            "color": "#777777"
          }
        }
      },
      {
        "id": "signature_label",
        "displayName": "Signature Label",
        "type": "text",
        "renderPass": "text",
        "zIndex": 15,
        "state": { "visible": true, "locked": false },
        "interaction": { "selectable": true, "movable": true, "editable": true },
        "bounds": { "x": 650, "y": 580, "width": 200, "height": 20 },
        "transform": { "rotation": 0.0, "pivot": { "x": 0.5, "y": 0.5 } },
        "content": {
          "text": "PRINCIPAL / DIRECTOR",
          "fontFamily": "System",
          "fontSize": 12.0,
          "color": "#666666",
          "align": "center",
          "fontWeight": "600"
        }
      }
    ]
  }
}
```
