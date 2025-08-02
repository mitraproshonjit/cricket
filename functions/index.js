const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Aggregate player stats when ball events are added
exports.aggregatePlayerStats = functions.firestore
    .document('BallEvents/{ballId}')
    .onCreate(async (snap, context) => {
        const ballEvent = snap.data();
        const batch = db.batch();
        
        try {
            // Get innings and match info
            const inningsRef = db.collection('Innings').doc(ballEvent.innings_id);
            const inningsSnap = await inningsRef.get();
            const innings = inningsSnap.data();
            
            const matchRef = db.collection('Matches').doc(innings.match_id);
            const matchSnap = await matchRef.get();
            const match = matchSnap.data();
            
            // Update batter stats
            const batterStatsRef = db.collection('PlayerStats').doc(ballEvent.batter_id);
            const batterStatsSnap = await batterStatsRef.get();
            
            if (batterStatsSnap.exists) {
                const batterStats = batterStatsSnap.data();
                const updates = {
                    runs: batterStats.runs + ballEvent.runs_scored,
                    balls_faced: batterStats.balls_faced + (ballEvent.is_wide || ballEvent.is_no_ball ? 0 : 1),
                    fours: batterStats.fours + (ballEvent.runs_scored === 4 ? 1 : 0),
                    sixes: batterStats.sixes + (ballEvent.runs_scored === 6 ? 1 : 0),
                    last_updated: admin.firestore.FieldValue.serverTimestamp()
                };
                
                batch.update(batterStatsRef, updates);
            }
            
            // Update bowler stats
            const bowlerStatsRef = db.collection('PlayerStats').doc(ballEvent.bowler_id);
            const bowlerStatsSnap = await bowlerStatsRef.get();
            
            if (bowlerStatsSnap.exists) {
                const bowlerStats = bowlerStatsSnap.data();
                const oversBowled = ballEvent.is_wide || ballEvent.is_no_ball ? 
                    bowlerStats.overs_bowled : 
                    bowlerStats.overs_bowled + (1/6);
                
                const updates = {
                    runs_conceded: bowlerStats.runs_conceded + ballEvent.total_runs,
                    overs_bowled: oversBowled,
                    wickets: bowlerStats.wickets + (ballEvent.is_wicket && ballEvent.wicket_type !== 'run_out' ? 1 : 0),
                    last_updated: admin.firestore.FieldValue.serverTimestamp()
                };
                
                batch.update(bowlerStatsRef, updates);
            }
            
            await batch.commit();
            console.log('Player stats updated successfully');
            
        } catch (error) {
            console.error('Error updating player stats:', error);
            throw error;
        }
    });

// Update match stats when innings are completed
exports.updateMatchStats = functions.firestore
    .document('Innings/{inningsId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if innings just completed
        if (before.status !== 'completed' && after.status === 'completed') {
            try {
                // Update player match and innings counts
                const matchTeamsSnap = await db.collection('MatchTeams')
                    .where('match_id', '==', after.match_id)
                    .where('team', '==', after.team)
                    .get();
                
                const batch = db.batch();
                
                for (const teamDoc of matchTeamsSnap.docs) {
                    const team = teamDoc.data();
                    const playerStatsRef = db.collection('PlayerStats').doc(team.player_id);
                    
                    batch.update(playerStatsRef, {
                        matches: admin.firestore.FieldValue.increment(1),
                        innings: admin.firestore.FieldValue.increment(1),
                        last_updated: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
                
                await batch.commit();
                console.log('Match stats updated for completed innings');
                
            } catch (error) {
                console.error('Error updating match stats:', error);
            }
        }
    });

// Create player stats when new player is added
exports.initializePlayerStats = functions.firestore
    .document('Players/{playerId}')
    .onCreate(async (snap, context) => {
        const player = snap.data();
        const playerId = context.params.playerId;
        
        try {
            const playerStats = {
                player_id: playerId,
                matches: 0,
                innings: 0,
                runs: 0,
                balls_faced: 0,
                wickets: 0,
                overs_bowled: 0.0,
                runs_conceded: 0,
                fours: 0,
                sixes: 0,
                last_updated: admin.firestore.FieldValue.serverTimestamp()
            };
            
            await db.collection('PlayerStats').doc(playerId).set(playerStats);
            console.log(`Player stats initialized for ${playerId}`);
            
        } catch (error) {
            console.error('Error initializing player stats:', error);
            throw error;
        }
    });

// Clean up player stats when player is deleted
exports.cleanupPlayerStats = functions.firestore
    .document('Players/{playerId}')
    .onDelete(async (snap, context) => {
        const playerId = context.params.playerId;
        
        try {
            await db.collection('PlayerStats').doc(playerId).delete();
            console.log(`Player stats cleaned up for ${playerId}`);
            
        } catch (error) {
            console.error('Error cleaning up player stats:', error);
        }
    });

// Handle match transfer acceptance
exports.handleMatchTransfer = functions.firestore
    .document('MatchTransfers/{transferId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if transfer was just accepted
        if (!before.accepted && after.accepted) {
            try {
                // Update match with new scorer
                const matchRef = db.collection('Matches').doc(after.match_id);
                await matchRef.update({
                    current_scorer_id: after.to_user_id
                });
                
                console.log(`Match ${after.match_id} transferred to ${after.to_user_id}`);
                
            } catch (error) {
                console.error('Error handling match transfer:', error);
                throw error;
            }
        }
    });

// Validate pool membership when adding users
exports.validatePoolMembership = functions.firestore
    .document('PoolMemberships/{membershipId}')
    .onCreate(async (snap, context) => {
        const membership = snap.data();
        
        try {
            // Check if user exists
            const userSnap = await db.collection('Users').doc(membership.user_id).get();
            if (!userSnap.exists) {
                console.error(`User ${membership.user_id} does not exist`);
                await snap.ref.delete();
                return;
            }
            
            // Check if pool exists
            const poolSnap = await db.collection('PlayerPools').doc(membership.pool_id).get();
            if (!poolSnap.exists) {
                console.error(`Pool ${membership.pool_id} does not exist`);
                await snap.ref.delete();
                return;
            }
            
            console.log(`Pool membership validated for user ${membership.user_id}`);
            
        } catch (error) {
            console.error('Error validating pool membership:', error);
            // Delete invalid membership
            await snap.ref.delete();
        }
    });

// Generate match summary when match is completed
exports.generateMatchSummary = functions.firestore
    .document('Matches/{matchId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if match was just completed
        if (before.status !== 'completed' && after.status === 'completed') {
            try {
                const matchId = context.params.matchId;
                
                // Get all innings for this match
                const inningsSnap = await db.collection('Innings')
                    .where('match_id', '==', matchId)
                    .orderBy('innings_number')
                    .get();
                
                // Get all ball events for this match
                const ballEventsSnap = await db.collection('BallEvents')
                    .where('innings_id', 'in', inningsSnap.docs.map(doc => doc.id))
                    .orderBy('ball_sequence')
                    .get();
                
                // Generate match summary
                const summary = {
                    match_id: matchId,
                    team_a_name: after.team_a_name,
                    team_b_name: after.team_b_name,
                    total_innings: inningsSnap.size,
                    total_balls: ballEventsSnap.size,
                    completed_at: admin.firestore.FieldValue.serverTimestamp(),
                    innings_summary: inningsSnap.docs.map(doc => {
                        const innings = doc.data();
                        return {
                            innings_number: innings.innings_number,
                            team: innings.team,
                            runs: innings.runs,
                            wickets: innings.wickets,
                            overs: innings.overs_faced
                        };
                    })
                };
                
                await db.collection('MatchSummaries').doc(matchId).set(summary);
                console.log(`Match summary generated for ${matchId}`);
                
            } catch (error) {
                console.error('Error generating match summary:', error);
            }
        }
    });

// HTTP function to get player rankings
exports.getPlayerRankings = functions.https.onCall(async (data, context) => {
    // Check authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { poolId, category } = data;
    
    try {
        // Verify user has access to this pool
        const membershipSnap = await db.collection('PoolMemberships')
            .where('pool_id', '==', poolId)
            .where('user_id', '==', context.auth.uid)
            .get();
            
        if (membershipSnap.empty) {
            throw new functions.https.HttpsError('permission-denied', 'User not in pool');
        }
        
        // Get players in pool
        const playersSnap = await db.collection('Players')
            .where('pool_id', '==', poolId)
            .get();
        
        const playerIds = playersSnap.docs.map(doc => doc.id);
        
        // Get player stats
        const statsSnap = await db.collection('PlayerStats')
            .where('player_id', 'in', playerIds)
            .get();
        
        // Sort by category
        let rankings = [];
        for (const statDoc of statsSnap.docs) {
            const stats = statDoc.data();
            const playerDoc = playersSnap.docs.find(p => p.id === stats.player_id);
            const player = playerDoc.data();
            
            rankings.push({
                player_id: stats.player_id,
                player_name: player.name,
                ...stats
            });
        }
        
        // Sort based on category
        switch (category) {
            case 'runs':
                rankings.sort((a, b) => b.runs - a.runs);
                break;
            case 'wickets':
                rankings.sort((a, b) => b.wickets - a.wickets);
                break;
            case 'average':
                rankings.sort((a, b) => (b.runs / Math.max(b.innings, 1)) - (a.runs / Math.max(a.innings, 1)));
                break;
            default:
                rankings.sort((a, b) => b.runs - a.runs);
        }
        
        return rankings.slice(0, 20); // Top 20
        
    } catch (error) {
        console.error('Error getting player rankings:', error);
        throw new functions.https.HttpsError('internal', 'Error fetching rankings');
    }
});