# Cricket Scorer iOS App

A comprehensive SwiftUI app for scoring weekend amateur cricket matches with real-time collaboration, player pools, and detailed statistics tracking.

## 🏏 Features

### Core Functionality
- **Match Scoring**: Complete cricket scoring with all standard rules
- **Player Pools**: Shared player databases across multiple users
- **Role-based Access**: Admin, Moderator, and User roles with appropriate permissions
- **Real-time Collaboration**: Live match updates and scoring transfer
- **Statistics Tracking**: Comprehensive batting and bowling statistics

### Scoring Features
- Standard cricket scoring (0-6 runs per ball)
- Wide and No Ball handling
- All wicket types (Bowled, Caught, LBW, Run Out, Stumped, etc.)
- Grant Without Ball functionality
- Undo last ball feature
- Over and innings management
- Target chasing for second innings

### Match Setup
- Team selection from player pools
- Customizable match formats (5-50 overs)
- Toss handling (winner chooses to bat or field)
- Single or double innings matches
- Captain selection (first player in team)
- Common Player support (can play for both teams)

### Player Management
- Player attributes (name, batting hand, bowling hand, bowling style)
- Link players to user accounts
- Persistent statistics across matches
- Add/remove players with role-based permissions

### User Roles & Permissions

#### Admin
- Create and manage player pools
- Add/remove players and users
- Assign moderator roles
- Full match scoring capabilities
- Transfer match scoring rights

#### Moderator  
- Add/remove players
- Full match scoring capabilities
- Transfer match scoring rights

#### User
- View pool and match data
- Score matches when assigned
- Transfer match scoring rights

## 🛠 Technical Architecture

### Frontend (iOS - SwiftUI)
- **MVVM Architecture**: Clean separation of concerns
- **Firebase SDK**: Authentication, Firestore, Cloud Functions
- **Real-time Updates**: Firestore listeners for live data sync
- **Responsive UI**: Optimized for both portrait and landscape orientations

### Backend (Firebase)
- **Firebase Auth**: Email/password authentication
- **Firestore**: NoSQL database with real-time sync
- **Cloud Functions**: Server-side logic for stats aggregation
- **Security Rules**: Role-based access control

### Database Schema

#### Collections:
- `Users` - User authentication data
- `PlayerPools` - Pool information
- `PoolMemberships` - User roles in pools
- `Players` - Player profiles and attributes
- `PlayerStats` - Aggregated statistics
- `Matches` - Match configuration and status
- `MatchTeams` - Team compositions
- `Innings` - Innings data and current state
- `BallEvents` - Individual ball records
- `MatchTransfers` - Scoring transfer requests

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+
- Firebase project with Auth, Firestore, and Functions enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/cricket-scorer-ios.git
   cd cricket-scorer-ios
   ```

2. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication with Email/Password
   - Create a Firestore database
   - Download `GoogleService-Info.plist` and add to your Xcode project

3. **Install Dependencies**
   ```bash
   # Using Swift Package Manager (SPM)
   # Firebase dependencies are already configured in Package.swift
   ```

4. **Deploy Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

6. **Build and Run**
   - Open `CricketScorer.xcodeproj` in Xcode
   - Select your target device/simulator
   - Build and run (⌘+R)

### Test Data

The app includes a test data generator for development and testing:

```swift
// Generate test data
await TestDataGenerator.shared.generateTestData()

// Simulate a complete match
await TestDataGenerator.shared.simulateMatch(matchId: "your-match-id")

// Clear all test data
await TestDataGenerator.shared.clearTestData()
```

## 📱 App Navigation

### Main Flow
1. **Login/Register** - Email/password authentication
2. **Pool Dashboard** - Main hub showing pool info and quick actions
3. **Match Setup** - 4-step wizard for creating matches
4. **Live Scoring** - Real-time scoring interface
5. **Pool Management** - Player and user management

### Key Screens
- `LoginView` - Authentication
- `PoolDashboardView` - Main dashboard
- `MatchSetupView` - Match creation wizard
- `LiveScoringView` - Live match scoring
- `PoolManagementView` - Pool administration

## 🔐 Security

### Firestore Security Rules
- Role-based access control
- Data validation at database level
- Prevention of unauthorized modifications
- Match scorer verification for live updates

### Key Security Features
- Only authenticated users can access data
- Pool membership required for all operations
- Role-based permissions enforced server-side
- Match scoring limited to designated scorer
- Stats updates only via Cloud Functions

## 🏗 Architecture Decisions

### State Management
- `@StateObject` and `@ObservableObject` for reactive UI
- Firestore listeners for real-time data sync
- MVVM pattern with clear data flow

### Data Persistence
- Firestore for all persistent data
- Real-time listeners for live updates
- Offline capability with Firestore caching

### Error Handling
- Comprehensive error states in ViewModels
- User-friendly error messages
- Graceful degradation for network issues

## 🧪 Testing

### Test Data Generation
- Automated test user creation
- Sample player pools with realistic data
- Match simulation for testing scoring flow

### Manual Testing Scenarios
1. **User Registration & Pool Creation**
2. **Multi-user Pool Management**
3. **Match Setup & Team Selection**
4. **Live Scoring with Multiple Ball Types**
5. **Match Transfer Between Users**
6. **Statistics Accuracy**

## 🔄 Development Workflow

### Adding New Features
1. Update Firestore data models if needed
2. Modify security rules for new data access patterns
3. Create/update ViewModels for business logic
4. Build SwiftUI views with proper state management
5. Test with multiple user roles
6. Update Cloud Functions if server-side logic needed

### Code Organization
```
CricketScorer/
├── Models/           # Data models and enums
├── Managers/         # Business logic and Firebase interface
├── Views/           # SwiftUI views organized by feature
├── Firebase/        # Firebase configuration
├── Utils/           # Utilities and test data
└── Resources/       # Assets and configuration files
```

## 📊 Statistics Tracking

### Batting Stats
- Runs, balls faced, innings played
- Fours and sixes
- Batting average and strike rate
- Match participation

### Bowling Stats  
- Wickets taken, overs bowled
- Runs conceded, economy rate
- Bowling average
- Match participation

### Real-time Aggregation
- Cloud Functions update stats on each ball
- Efficient batch updates for performance
- Historical data preservation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow SwiftUI and MVVM best practices
- Write descriptive commit messages
- Update documentation for new features
- Test with multiple user roles
- Ensure real-time sync works correctly

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Firebase team for excellent real-time database
- SwiftUI community for UI/UX inspiration
- Cricket enthusiasts who provided domain expertise

---

**Built with ❤️ for cricket lovers everywhere** 🏏