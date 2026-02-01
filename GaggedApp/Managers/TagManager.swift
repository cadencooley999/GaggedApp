//
//  TagManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/2/26.
//

import FirebaseFirestore


class TagManager {
    static let shared = TagManager()
    
    let tagCollection: CollectionReference = Firestore.firestore().collection("Tags")
    let catCollection: CollectionReference = Firestore.firestore().collection("TagCategories")

    
    func seedTags() async throws {
        let db = Firestore.firestore()
        let collection = db.collection("Tags")

        for tag in tagList {
            try await collection
                .document(tag.id)
                .setData([
                    "title": tag.title,
                    "category": tag.category
                ], merge: false)
        }
    }
    
    func loadTags() async throws -> [TagModel] {
        let snapshot = try await tagCollection.getDocuments()
        return snapshot.documents.compactMap(TagModel.init)
    }
    
    func loadCategories() async throws -> [TagCategory] {
        let snapshot = try await catCollection.getDocuments()
        return snapshot.documents.compactMap(TagCategory.init)
    }
    
    func mapCategory(doc: QueryDocumentSnapshot) -> TagCategory {
        let title = doc["name"] as? String ?? ""
        let order = doc["order"] as? NSNumber ?? 0 as NSNumber
        
        return TagCategory(id: doc.documentID, title: title, order: order.intValue)
    }
    
    var tagList: [TagModel] = [
        
        // MARK: - Hot Take
        TagModel(id: "HotTake", category: "Hot Take", title: "HotTake"),
        TagModel(id: "UnpopularOpinion", category: "Hot Take", title: "UnpopularOpinion"),
        TagModel(id: "SayItWithChest", category: "Hot Take", title: "SayItWithChest"),
        TagModel(id: "NoFilter", category: "Hot Take", title: "NoFilter"),
        TagModel(id: "SorryNotSorry", category: "Hot Take", title: "SorryNotSorry"),

        // MARK: - Behaviour
        TagModel(id: "RedFlag", category: "Behavior", title: "RedFlag"),
        TagModel(id: "GreenFlag", category: "Behavior", title: "GreenFlag"),
        TagModel(id: "WalkingIck", category: "Behavior", title: "WalkingIck"),
        TagModel(id: "GoodVibesOnly", category: "Behavior", title: "GoodVibesOnly"),
        TagModel(id: "MainCharacterEnergy", category: "Behavior", title: "MainCharacterEnergy"),
        TagModel(id: "PickMeEnergy", category: "Behavior", title: "PickMeEnergy"),
        TagModel(id: "SideCharacterBehavior", category: "Behavior", title: "SideCharacterBehavior"),
        TagModel(id: "Embarrassing", category: "Behavior", title: "Embarrassing"),
        TagModel(id: "ReputationCheck", category: "Behavior", title: "ReputationCheck"),
        TagModel(id: "TwoFaced", category: "Behavior", title: "TwoFaced"),
        
        // MARK: - Funny
        TagModel(id: "Funny", category: "Funny", title: "Funny"),
        TagModel(id: "DarkHumor", category: "Funny", title: "DarkHumor"),
        TagModel(id: "LaughOrCry", category: "Funny", title: "LaughOrCry"),
        
        // MARK: - Shock
        TagModel(id: "JawDropped", category: "Shock", title: "JawDropped"),
        TagModel(id: "Speechless", category: "Shock", title: "Speechless"),
        TagModel(id: "Unreal", category: "Shock", title: "Unreal"),
        TagModel(id: "IWasNotReady", category: "Shock", title: "IWasNotReady"),
        TagModel(id: "Gagged", category: "Shock", title: "Gagged"),
        
        // MARK: - Tea
        TagModel(id: "Tea", category: "Tea", title: "Tea"),
        TagModel(id: "TeaTime", category: "Tea", title: "TeaTime"),
        TagModel(id: "ColdHardTea", category: "Tea", title: "ColdHardTea"),
        TagModel(id: "BitterTea", category: "Tea", title: "BitterTea"),
        TagModel(id: "PoisonTea", category: "Tea", title: "PoisonTea"),

        // MARK: - Drama
        TagModel(id: "DramaAlert", category: "Drama", title: "DramaAlert"),
        TagModel(id: "HereWeGoAgain", category: "Drama", title: "HereWeGoAgain"),
        TagModel(id: "Toxic", category: "Drama", title: "Toxic"),
        TagModel(id: "CrossedTheLine", category: "Drama", title: "CrossedTheLine"),
        TagModel(id: "BurnItDown", category: "Drama", title: "BurnItDown"),

        // MARK: - Confession
        TagModel(id: "Confession", category: "Confession", title: "Confession"),
        TagModel(id: "AnonymousConfession", category: "Confession", title: "AnonymousConfession"),
        TagModel(id: "SkeletonsOut", category: "Confession", title: "SkeletonsOut"),
        TagModel(id: "Exposed", category: "Confession", title: "Exposed"),

        // MARK: - Praise
        TagModel(id: "GiveThemFlowers", category: "Praise", title: "GiveThemFlowers"),
        TagModel(id: "WellDeserved", category: "Praise", title: "WellDeserved"),
        TagModel(id: "GoodEnergy", category: "Praise", title: "GoodEnergy"),
        TagModel(id: "NotAllBad", category: "Praise", title: "NotAllBad"),
        TagModel(id: "FakeNice", category: "Praise", title: "FakeNice"),

        // MARK: - Relationships
        TagModel(id: "Situationship", category: "Relationships", title: "Situationship"),
        TagModel(id: "TalkingStage", category: "Relationships", title: "TalkingStage"),
        TagModel(id: "ItsComplicated", category: "Relationships", title: "ItsComplicated"),
        TagModel(id: "CaughtLacking", category: "Relationships", title: "CaughtLacking"),
        TagModel(id: "Heartbreaker", category: "Relationships", title: "Heartbreaker"),

        // MARK: - School
        TagModel(id: "CampusTea", category: "School", title: "CampusTea"),
        TagModel(id: "ProfessorProblems", category: "School", title: "ProfessorProblems"),
        TagModel(id: "EveryoneKnows", category: "School", title: "EveryoneKnows"),

        // MARK: - Workplace
        TagModel(id: "HRNightmare", category: "Workplace", title: "HRNightmare"),
        TagModel(id: "ToxicJob", category: "Workplace", title: "ToxicJob"),
        TagModel(id: "GettingReported", category: "Workplace", title: "GettingReported"),

        // MARK: - Internet
        TagModel(id: "ScreenshotsExist", category: "Internet", title: "ScreenshotsExist"),
        TagModel(id: "DeletedPost", category: "Internet", title: "DeletedPost"),
        TagModel(id: "ChronicallyOnline", category: "Internet", title: "ChronicallyOnline"),
        TagModel(id: "Receipts", category: "Internet", title: "Receipts"),
        TagModel(id: "ScreensDontLie", category: "Internet", title: "ScreensDontLie"),
        TagModel(id: "ExhibitA", category: "Internet", title: "ExhibitA"),
        TagModel(id: "CaseClosed", category: "Internet", title: "CaseClosed"),
        TagModel(id: "InternetNeverForgets", category: "Internet", title: "InternetNeverForgets"),

        // MARK: - Awkward
        TagModel(id: "HardToWatch", category: "Awkward", title: "HardToWatch"),
        TagModel(id: "CringeCore", category: "Awkward", title: "CringeCore"),
        TagModel(id: "MissedThePoint", category: "Awkward", title: "MissedThePoint"),
        TagModel(id: "Yikes", category: "Awkward", title: "Yikes"),

        // MARK: - Shady
        TagModel(id: "Petty", category: "Shady", title: "Petty"),
        TagModel(id: "SneakDiss", category: "Shady", title: "SneakDiss"),
        TagModel(id: "ShadeThrown", category: "Shady", title: "ShadeThrown"),
        TagModel(id: "Backhanded", category: "Shady", title: "Backhanded"),
        TagModel(id: "VillainEra", category: "Shady", title: "VillainEra"),

        // MARK: - Reflection
        TagModel(id: "JustThinking", category: "Reflection", title: "JustThinking"),
        TagModel(id: "RealTalk", category: "Reflection", title: "RealTalk"),
        TagModel(id: "SomethingToThinkAbout", category: "Reflection", title: "SomethingToThinkAbout"),
        TagModel(id: "GrayArea", category: "Reflection", title: "GrayArea"),
        TagModel(id: "QuestionableChoices", category: "Reflection", title: "QuestionableChoices"),
        TagModel(id: "NotOkay", category: "Reflection", title: "NotOkay"),
        TagModel(id: "SoundOff", category: "Reflection", title: "SoundOff"),

        // MARK: - Callout
        TagModel(id: "Problematic", category: "Callouts", title: "Problematic"),
        TagModel(id: "DoBetter", category: "Callouts", title: "DoBetter"),
        TagModel(id: "ThisIsWhy", category: "Callouts", title: "ThisIsWhy"),
        TagModel(id: "RumorMill", category: "Callouts", title: "RumorMill"),
        TagModel(id: "Allegedly", category: "Callouts", title: "Allegedly"),

        // MARK: - Chaos
        TagModel(id: "PureChaos", category: "Chaos", title: "PureChaos"),
        TagModel(id: "Unhinged", category: "Chaos", title: "Unhinged"),
        TagModel(id: "OutOfPocket", category: "Chaos", title: "OutOfPocket"),
        TagModel(id: "DerangedEnergy", category: "Chaos", title: "DerangedEnergy"),

        // MARK: - Updates
        TagModel(id: "JustDropped", category: "Updates", title: "JustDropped"),
        TagModel(id: "Update", category: "Updates", title: "Update"),
        TagModel(id: "DevelopingStory", category: "Updates", title: "DevelopingStory"),
        TagModel(id: "ThisJustIn", category: "Updates", title: "ThisJustIn"),
        TagModel(id: "LateUpdate", category: "Updates", title: "LateUpdate"),
        TagModel(id: "ItsGettingWorse", category: "Updates", title: "ItsGettingWorse"),

        // MARK: - Endgame
        TagModel(id: "NoGoingBack", category: "Endgame", title: "NoGoingBack"),
        TagModel(id: "BridgesBurnt", category: "Endgame", title: "BridgesBurnt"),
        TagModel(id: "Aftermath", category: "Endgame", title: "Aftermath"),
        TagModel(id: "TooFarGone", category: "Endgame", title: "TooFarGone"),
        TagModel(id: "FinalStraw", category: "Endgame", title: "FinalStraw")
    ]
    
    var categories: [TagCategory] = [
        TagCategory(id: "cat1",  title: "Hot Take",        order: 1),
        TagCategory(id: "cat2",  title: "Behavior",        order: 2),
        TagCategory(id: "cat3",  title: "Funny",           order: 3),
        TagCategory(id: "cat4",  title: "Shock",           order: 4),
        TagCategory(id: "cat5",  title: "Tea",             order: 5),
        TagCategory(id: "cat6",  title: "Drama",           order: 6),
        TagCategory(id: "cat7",  title: "Confession",      order: 7),
        TagCategory(id: "cat8",  title: "Praise",          order: 8),
        TagCategory(id: "cat9",  title: "Relationships",   order: 9),
        TagCategory(id: "cat10", title: "School",          order: 10),
        TagCategory(id: "cat11", title: "Workplace",       order: 11),
        TagCategory(id: "cat12", title: "Internet",        order: 12),
        TagCategory(id: "cat13", title: "Awkward",         order: 13),
        TagCategory(id: "cat14", title: "Shady",           order: 14),
        TagCategory(id: "cat15", title: "Reflection",      order: 15),
        TagCategory(id: "cat16", title: "Callout",         order: 16),
        TagCategory(id: "cat17", title: "Chaos",           order: 17),
        TagCategory(id: "cat18", title: "Updates",         order: 18),
        TagCategory(id: "cat19", title: "Endgame",         order: 19)
    ]
}
