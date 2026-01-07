import Foundation

/// Quality presets for image generation
struct QualityPreset {
    let name: String
    let steps: Int
    let cfgScale: Double
    let description: String
    let estimatedTime: String
}

/// Predefined quality presets based on testing results
enum QualityPresets {
    static let fast = QualityPreset(
        name: "Fast",
        steps: 15,
        cfgScale: 7.5,
        description: "Quick preview quality",
        estimatedTime: "5-7 seconds"
    )
    
    static let balanced = QualityPreset(
        name: "Balanced",
        steps: 30,
        cfgScale: 8.0,
        description: "Recommended for most cases",
        estimatedTime: "12-15 seconds"
    )
    
    static let premium = QualityPreset(
        name: "Premium",
        steps: 40,
        cfgScale: 8.5,
        description: "Maximum quality for final outputs",
        estimatedTime: "17-20 seconds"
    )
    
    static let all: [QualityPreset] = [fast, balanced, premium]
}

/// Example prompts with quality keywords
struct PromptExample {
    let category: String
    let prompt: String
    let negativePrompt: String
    let description: String
}

/// Curated example prompts for high quality results
enum PromptExamples {
    static let portrait = PromptExample(
        category: "Portrait",
        prompt: "professional portrait of a beautiful woman, detailed face, high quality, photorealistic, 8k uhd, studio lighting, sharp focus, physically-based rendering",
        negativePrompt: "ugly, deformed, disfigured, poor details, bad anatomy, lowres, low quality, blurry, distorted face, duplicate, mutated, extra limbs, bad proportions",
        description: "High-quality portrait with professional lighting"
    )
    
    static let closeUp = PromptExample(
        category: "Close-up",
        prompt: "close-up portrait of a young woman with natural beauty, detailed facial features, soft skin, professional studio lighting, shallow depth of field, bokeh background, photorealistic, high resolution",
        negativePrompt: "ugly, deformed face, bad anatomy, asymmetric face, bad eyes, crossed eyes, lazy eye, mutation, extra limbs, bad hands, poorly drawn face, distorted, blurry, low quality, artificial, cartoon, anime, drawing",
        description: "Detailed close-up with shallow depth of field"
    )
    
    static let masterpiece = PromptExample(
        category: "Masterpiece",
        prompt: "masterpiece, best quality, ultra detailed portrait of a beautiful woman, perfect face, natural skin texture, soft lighting, photorealistic, professional photography, 8k resolution",
        negativePrompt: "ugly, deformed, disfigured, bad anatomy, bad proportions, cloned face, malformed limbs, missing arms, missing legs, extra arms, extra legs, fused fingers, too many fingers, long neck, cross-eyed, mutation, poorly drawn hands, poorly drawn face, low quality, lowres, blurry, grainy, jpeg artifacts",
        description: "Maximum quality with detailed negative prompt"
    )
    
    static let landscape = PromptExample(
        category: "Landscape",
        prompt: "sunset over mountains, landscape photography, golden hour, dramatic lighting, high quality, photorealistic, 8k uhd, wide angle, professional photography",
        negativePrompt: "people, buildings, urban, low quality, blurry, distorted, overexposed, underexposed",
        description: "Natural landscape with dramatic lighting"
    )
    
    static let all: [PromptExample] = [portrait, closeUp, masterpiece, landscape]
}

/// Quality keywords to enhance prompts
enum QualityKeywords {
    static let technical = [
        "high quality",
        "photorealistic",
        "8k uhd",
        "8k resolution",
        "sharp focus",
        "detailed",
        "ultra detailed",
        "physically-based rendering"
    ]
    
    static let artistic = [
        "masterpiece",
        "best quality",
        "professional",
        "studio lighting",
        "soft lighting",
        "dramatic lighting",
        "professional photography"
    ]
    
    static let composition = [
        "sharp focus",
        "shallow depth of field",
        "bokeh background",
        "wide angle",
        "portrait",
        "close-up"
    ]
    
    static let negative = [
        "ugly",
        "deformed",
        "disfigured",
        "bad anatomy",
        "bad proportions",
        "poorly drawn face",
        "poorly drawn hands",
        "low quality",
        "lowres",
        "blurry",
        "grainy",
        "distorted",
        "jpeg artifacts",
        "mutation",
        "extra limbs",
        "cloned face"
    ]
}
