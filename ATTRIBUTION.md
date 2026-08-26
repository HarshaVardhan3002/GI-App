# Attribution

## Upstream

This project is a derivative work of
**[flutter_instagram_offline_first_clone](https://github.com/Gambley1/flutter_instagram_offline_first_clone)**
by **Emil Zulufov (ezIT)**, © 2024, used under the MIT License. The full licence
text ships unmodified at [`app/LICENSE`](app/LICENSE).

That licence carries a clause beyond standard MIT:

> While this software is released under the MIT License, the direct use of the
> unmodified and/or modified source code in its entirety is not permitted
> without express written permission from the copyright holder. Derivative
> works based on this software are allowed under the terms of the MIT License,
> provided they are substantially modified and do not constitute a mere
> replication of the original code.

**What this obliges us to do.** The product being built here is a daily
learning app for gastroenterologists - a different product with a different
audience, a different content model and a different feature set. Meeting the
clause is not automatic; it is met by the work: removing the Instagram identity
entirely, cutting the social feature set down to what a clinical reader needs,
and replacing the backend. Until that work lands, this repository is closer to a
replication than to a derivative work, and that is a licensing exposure, not
just an aesthetic one.

**What must never be removed:** `app/LICENSE`, the copyright line inside it, and
this file.

## Datasets

Endoscopic images come only from open, de-identified datasets under
CC BY 4.0. Attribution renders on screen next to every image, and the licence
metadata travels with each image record in `app/assets/content/images.json`.

- **HyperKvasir** - Borgli et al., Simula.
 <https://datasets.simula.no/hyper-kvasir/>
- **GastroVision** - Jha et al.
 <https://github.com/DebeshJha/GastroVision>

No patient data is used, and none may be added.

## Clinical guidelines

Guideline content belongs to the **AWMF author collective**. This project quotes
at most 400 characters per recommendation, always alongside a full citation, and
never redistributes guideline text. Shipping to real users requires a separate
rights agreement with the AWMF; nothing in this repository substitutes for one.

## Fonts

Inter, under the SIL Open Font License, bundled in `app/packages/app_ui`.
