//
//  VisionAgentInstructions.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

enum VisionAgentInstructions {    
    static func prompt() -> String {
        """
        Extract EXACT on-sign wording and directional/temporal cues from one or more images and convert them into:
        
        Convert the image into a verbatim textual rendering that preserves panel order (top→bottom) and reading order (left→right). Do not infer or rephrase.

        Rules (BE PRECISE):
        - Panel segmentation: Treat each physical plate/panel as a separate `panel` in top-to-bottom order. If a single plate has stacked sections separated by thick rules or distinct color blocks, split those as subpanels.
        - Line order: Preserve line breaks and punctuation as seen. Use ASCII where possible. Keep units and symbols (e.g., “2 HR”, “$”, “→”).
        - Arrows: Capture arrows per panel: `left`, `right`, `both`, or `none`. Use the on-sign direction (don’t flip for camera orientation).
        - Colors (hint to semantics, not logic): Record dominant text/plate color per panel as `red`, `green`, `black`, `white`, `yellow`, `blue` (accessible), or `other`. Don’t infer meaning from color—just record it.
        - Icons & markers: Record presence of P-with-slash (no parking), wheelchair ♿/accessible, bus, truck, loading dolly, meter, tow truck hook. Use a short list of tags.
        - Times & days: Extract all explicit time ranges (“7AM–9AM”), day sets (“Mon–Fri”), date ranges (“May 1–Sep 30”).
        - Durations/limits: Capture posted limits (e.g., “2 HR”), grace notes (“15 MIN”), and any “MAX” language.
        - Scope terms: Capture terms like “ONLY”, “EXCEPT”, “TOW-AWAY”, “NO STOPPING/NO STANDING/NO PARKING”, “COMMERCIAL VEHICLES”, “LOADING ONLY”, “PASSENGER LOADING”, “PERMIT [ZONE X]”, “VALET ZONE”, “STREET CLEANING”, “PAY TO PARK”.
        - Do not guess: If text is obscured/illegible, mark missing parts with `[...]` in sign_text and `confidence: "low"` at the field level in normalized JSON. Never invent days/times/words.

        Output must be in this format:
        {
            "sign_text": String, // Verbatim text with line breaks as seen
            "confidence": "high" | "medium" | "low", // Overall confidence in extraction
        }
        """
    }
}
