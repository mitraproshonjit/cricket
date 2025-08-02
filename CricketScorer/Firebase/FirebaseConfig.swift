import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        // Enable network logging in debug mode
        #if DEBUG
        Firestore.enableLogging(true)
        #endif
    }
    
    var db: Firestore {
        Firestore.firestore()
    }
    
    var auth: Auth {
        Auth.auth()
    }
    
    // Collection references
    var usersCollection: CollectionReference {
        db.collection("Users")
    }
    
    var playerPoolsCollection: CollectionReference {
        db.collection("PlayerPools")
    }
    
    var poolMembershipsCollection: CollectionReference {
        db.collection("PoolMemberships")
    }
    
    var playersCollection: CollectionReference {
        db.collection("Players")
    }
    
    var playerStatsCollection: CollectionReference {
        db.collection("PlayerStats")
    }
    
    var matchesCollection: CollectionReference {
        db.collection("Matches")
    }
    
    var matchTeamsCollection: CollectionReference {
        db.collection("MatchTeams")
    }
    
    var inningsCollection: CollectionReference {
        db.collection("Innings")
    }
    
    var ballEventsCollection: CollectionReference {
        db.collection("BallEvents")
    }
    
    var matchTransfersCollection: CollectionReference {
        db.collection("MatchTransfers")
    }
}