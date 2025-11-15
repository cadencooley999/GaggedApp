//
//  ProfanityFilter.swift
//  CommonsDining
//
//  Created by Caden Cooley on 6/16/25.
//


import Foundation

struct ProfanityFilter {
    
    static let bannedWords: [String] = ["2 girls 1 cup", "acrotomophilia", "alabama hot pocket", "alaskan pipeline", "anal", "anilingus", "anus", "apeshit", "arsehole", "ass", "asshole", "assmunch", "auto erotic", "autoerotic", "babeland", "baby batter", "baby juice", "ball gag", "ball gravy", "ball kicking", "ball licking", "ball sack", "ball sucking", "bangbros", "bangbus", "bareback", "barely legal", "barenaked", "bastard", "bastardo", "bastinado", "bbw", "bdsm", "beaner", "beaners", "beaver cleaver", "beaver lips", "beastiality", "bestiality", "big black", "big breasts", "big knockers", "big tits", "bimbos", "birdlock", "bitch", "bitches", "black cock", "blonde action", "blonde on blonde action", "blowjob", "blow job", "blow your load", "blue waffle", "blumpkin", "bollocks", "bondage", "boner", "boob", "boobs", "booty call", "brown showers", "brunette action", "bukkake", "bulldyke", "bullshit", "bung hole", "bunghole", "busty", "butt", "buttcheeks", "butthole", "camel toe", "camgirl", "camslut", "camwhore", "carpet muncher", "carpetmuncher", "chocolate rosebuds", "cialis", "circlejerk", "cleveland steamer", "clit", "clitoris", "clover clamps", "clusterfuck", "cock", "cocks", "coprolagnia", "coprophilia", "cornhole", "coon", "coons", "creampie", "cum", "cumming", "cumshot", "cumshots", "cunnilingus", "cunt", "darkie", "date rape", "daterape", "deep throat", "deepthroat", "dendrophilia", "dick", "dildo", "dingleberries", "dirty pillows", "dirty sanchez", "doggie style", "doggiestyle", "doggy style", "doggystyle", "dog style", "dolcett", "dominatrix", "dommes", "donkey punch", "double dong", "double penetration", "dp action", "dry hump", "dvda", "eat my ass", "ecchi", "ejaculation", "erotic", "erotism", "escort", "eunuch", "fag", "faggot", "fecal", "felch", "fellatio", "feltch", "female squirting", "femdom", "figging", "fingerbang", "fingering", "fisting", "foot fetish", "footjob", "frotting", "fuck", "fuck buttons", "fuckin", "fucking", "fucktards", "fudge packer", "fudgepacker", "futanari", "gangbang", "gang bang", "gay", "gay sex", "genitals", "giant cock", "girl on", "girl on top", "girls gone wild", "goatcx", "goatse", "god damn", "gokkun", "golden shower", "goodpoop", "goo girl", "goregasm", "grope", "group sex", "g-spot", "hand job", "handjob", "hentai", "homoerotic", "honkey", "hooker", "horny", "hot carl", "hot chick", "how to kill", "how to murder", "huge fat", "humping", "incest", "intercourse", "jack off", "jail bait", "jailbait", "jelly donut", "jerk off", "jigaboo", "jiggaboo", "jiggerboo", "jizz", "juggs", "kike", "kinbaku", "kinkster", "kinky", "knobbing", "leather restraint", "leather straight jacket", "lemon party", "livesex", "lolita", "lovemaking", "make me come", "male squirting", "masturbate", "masturbating", "masturbation", "menage a trois", "milf", "missionary position", "mong", "motherfucker", "mound of venus", "mr hands", "muff diver", "muffdiving", "nambla", "nawashi", "negro", "neonazi", "nigga", "nigger", "nig nog", "nimphomania", "nipple", "nipples", "nsfw", "nsfw images", "nazi", "nude", "nudity", "nutten", "nympho", "nymphomania", "octopussy", "omorashi", "one cup two girls", "one guy one jar", "orgasm", "orgy", "paedophile", "paki", "panties", "panty", "pedobear", "pedophile", "pegging", "penis", "phone sex", "piece of shit", "pikey", "pissing", "piss pig", "pisspig", "playboy", "pleasure chest", "pole smoker", "ponyplay", "poon", "poontang", "punany", "poop chute", "poopchute", "porn", "porno", "pornography", "pubes", "pussy", "queaf", "queef", "raghead", "raging boner", "rape", "raping", "rapist", "rectum", "reverse cowgirl", "rimjob", "rimming", "rosy palm", "rosy palm and her 5 sisters", "santorum", "schlong", "scissoring", "semen", "sex", "sexcam", "sexo", "sexy", "sexual", "sexually", "sexuality", "shaved beaver", "shaved pussy", "shibari", "shit", "shitty", "slanteye", "slut", "smut", "snatch", "snowballing", "sodomize", "sodomy", "spic", "splooge", "splooge moose", "spooge", "spread legs", "spunk", "strap on", "strapon", "strappado", "strip club", "style doggy", "suicide girls", "sultry women", "swastika", "tea bagging", "threesome", "throating", "tight white", "tit", "tits", "titties", "titty", "tongue in a", "towelhead", "tranny", "tribadism", "tub girl", "tubgirl", "twink", "two girls one cup", "undressing", "upskirt", "urethra play", "urophilia", "vagina", "venus mound", "viagra", "vibrator", "violet wand", "vorarephilia", "voyeur", "voyeurweb", "voyuer", "vulva", "wank", "wetback", "wet dream", "white power", "whore", "worldsex", "wrapping men", "wrinkled starfish", "xx", "xxx", "yellow showers", "zoophilia"]
    
    static let vowelVariants: [Character: String] = [
        "a": "[a@*]",
        "e": "[e3*]",
        "i": "[i1!*|]",
        "o": "[o0*]",
        "u": "[u*]"
    ]

    static func generateAsteriskRegexPatterns(words: [String]) -> [String] {
        var patterns: [String] = []

        for phrase in words {
            let parts = phrase.lowercased().split(separator: " ")
            var transformedParts: [String] = []

            for part in parts {
                var regexPart = ""
                for char in part {
                    if let variant = vowelVariants[char] {
                        regexPart += variant
                    } else if char.isLetter || char.isNumber {
                        regexPart += NSRegularExpression.escapedPattern(for: String(char))
                    } else {
                        regexPart += NSRegularExpression.escapedPattern(for: String(char))
                    }
                }
                transformedParts.append(regexPart)
            }

            // Allow space, underscore, or nothing between parts
            let joiner = "(?:\\W*)"
            let pattern = transformedParts.joined(separator: joiner)
            patterns.append(pattern)
        }

        return patterns
    }

    static func compileRegexPatterns(words: [String]) -> [NSRegularExpression] {
        let rawPatterns = generateAsteriskRegexPatterns(words: words)
        return rawPatterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
    }

    static func isUsernameClean(_ username: String, compiledPatterns: [NSRegularExpression]) -> Bool {
        for pattern in compiledPatterns {
            let range = NSRange(username.startIndex..., in: username)
            if pattern.firstMatch(in: username, options: [], range: range) != nil {
                return false
            }
        }
        return true
    }
}
