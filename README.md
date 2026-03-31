# Building StrangR Mobile App: From Idea to MVP

[Prototype StrangR APK File](https://drive.google.com/file/d/1PR1Bwr7NAxDMOcAIlieZXfxbwJY2ElP_/view?usp=sharing)
[Prototype StrangR Web App](https://strangr-shy.vercel.app/)
[Prototype StrangR Web App Git Repo](https://github.com/shagyeeen/StrangR.app)

I started building StrangR with a simple vision: create an anonymous chat platform where strangers connect purely through conversation. This is my journey building it for mobile.

## The Challenge

Most chat apps require profiles, verification, and lengthy onboarding. I wanted something raw and simple—just two strangers, a text box, and authentic conversation.

## What I Built

StrangR is a mobile-first real-time chat app where:
- Users get random matches with complete strangers
- Pure anonymity until mutual connection
- No profiles, no filters, no complexity
- Real-time messaging via Socket.io
- Friendship system with optional contact sharing

## Tech Stack I Chose

- Frontend: Flutter (cross-platform iOS and Android)
- Backend: Node.js with Express and Socket.io
- Database: Firebase (Firestore and Realtime DB)
- Authentication: Google Authentication
- Real-time: Firebase listeners and Socket.io WebSocket

I chose Flutter because:
- Single codebase for iOS and Android
- Hot reload for fast iteration
- Great performance for real-time apps
- Growing ecosystem and community support

## Building the Real-Time Chat

The hardest part was getting real-time messaging to work smoothly.

### Socket.io Implementation

First attempt: Basic Socket.io connection between Flutter app and Node.js backend.

Challenge: Connection drops when user switches apps or network changes.

Solution: Implement auto-reconnection with exponential backoff. This saved me hours of debugging.

The key was handling both success and failure gracefully. When network drops, automatically reconnect instead of showing error screens.

## Random Matching Algorithm

Getting random matching to work was trickier than expected.

First approach: Client asks backend for random user.

Problem: Race conditions. Two users could get matched, then both skip each other. Timing issues caused users to be paired twice or miss matches entirely.

Better approach:
1. User opens app - backend adds them to waiting queue
2. Backend checks if 2 or more users waiting
3. If yes - match pair, remove from queue, emit match event
4. If no - keep waiting

Much cleaner and eliminates race conditions.

## Handling App Lifecycle

Mobile is different from web. Apps suspend, resume, and lose connection unexpectedly. This was a steep learning curve.

Issue: User closes app mid-conversation. Server still thinks they're connected.

Solution: Listen to app lifecycle events. When app is backgrounded, save state locally and disconnect. When app resumes, reconnect and sync messages.

This ensures users don't lose messages and reconnect seamlessly.

## Building the UI

I used Flutter widgets to create an Instagram and WhatsApp-like experience.

Key UI components:
- Message list with auto-scroll to latest
- Message bubbles (different colors for sender vs recipient)
- Typing indicators
- Connection status indicator
- Connect button (request friendship)
- User counter showing online strangers

The design is intentionally minimal. No profile pictures, no user info—just the StrangR tag and messages.

## Push Notifications

Problem: Users miss messages if app is closed.

Solution: Firebase Cloud Messaging (FCM)

When a stranger sends a message, user gets notified even if app is closed. This increased message read rate significantly.

## Moderation Challenges

Initially, I had no moderation. Users started sending inappropriate content within the first week.

What I added:
1. Keyword filtering - basic inappropriate content detection
2. Reporting system - users can report inappropriate behavior
3. Banning - 5 reports equals 24-hour ban

This was a necessary evil. Early testing revealed that without basic moderation, the app becomes unusable. One toxic user can ruin the experience for 20 others.

## Performance Optimization

Early version was slow. The app felt laggy when messages arrived.

Problem 1: Rebuilding entire message list on every incoming message caused UI lag.

Solution: Use reactive programming to update only new messages instead of redrawing everything.

Problem 2: Storing all messages in memory made the app slow after 100 plus messages.

Solution: Implement pagination - load only last 50 messages initially, and load more when user scrolls up.

Result: App went from laggy to smooth.

## Biggest Mistake

I tried to build too many features at once:
- Random matching (Done)
- Real-time chat (Done)
- Friendship system (Done)
- Voice calls (Scrapped)
- Video calls (Scrapped)
- Group chats (Scrapped)

I scrapped voice, video, and groups early. Focus on core features first. Trying to be everything means you're nothing.

This was the hardest lesson. It felt like I was losing features but really I was gaining focus.

## What Worked Well

1. Socket.io for real-time - rock solid, worth every bit of complexity
2. Firebase for backend - no server management headaches, just build
3. Flutter for mobile - one codebase, both platforms, zero pain
4. Simple design - users actually liked the minimalist interface
5. Anonymous-first approach - differentiated from competitors like Omegle

## What I Would Do Differently

1. Start with Firebase Realtime DB only - Socket.io added complexity I didn't need immediately
2. Build web version first - web users give better, more thoughtful feedback
3. Hire a designer early - I spent weeks on UI polish that a designer could have done in days
4. Test moderation before launch - content moderation issues kill growth faster than bugs
5. Focus on retention, not features - one feature used well beats five features nobody uses

## Deployment Experience

Frontend: Flutter app to Google Play Store and App Store

Pain points:
- iOS approval took 2 weeks (Apple is slow)
- Android was instant (Google is fast)
- Store reviews were brutal (1-star reviews for small bugs)
- Need paid developer accounts (99 dollars Apple, 25 dollars Google annually)
- Update cycles are long (can't ship fixes instantly like web)

Backend: Node.js to Render (free tier with Google Cloud Scheduler keepalive)

Total deployment cost: Around 125 dollars per year (stores only) plus free hosting

The store approval process was frustrating. A bug I could fix in 10 minutes on web takes 2 weeks to fix on iOS.

## User Feedback

Early testers said:

"Why can't I choose who I talk to?"
Answer: That defeats the purpose. Random keeps it real and removes choice paralysis.

"People are mean"
Added reporting plus banning system. Learned that community moderation is essential.

"I got banned unfairly"
Added appeal process. Users want due process.

"The app crashes when I tab switch"
Fixed with proper lifecycle management. These edge cases are real on mobile.

Listening to users changed the app significantly. The app became what users wanted, not what I imagined.

## Growth Metrics

After 3 months of development:

- 500 downloads (mostly friends and family)
- 40 daily active users (2-3 percent conversion)
- Average session: 8 minutes
- 1-star to 5-star ratio: 60 to 40 (painful, but honest)

Small but genuinely engaged community. Quality beats quantity.

## Lessons from Building StrangR Mobile

1. Real-time is hard - connection management, reconnection, and state sync is non-trivial
2. Mobile lifecycle matters - apps pause, resume, and crash unexpectedly
3. Moderation is non-negotiable - launch with it, not after
4. Users want simplicity - every feature is a liability, not an asset
5. Feedback changes everything - build, listen, iterate, repeat
6. Performance matters - 100ms lag feels broken on mobile
7. Launch small - 100 engaged users beat 10K inactive ones
8. App stores are gatekeepers - they control your release schedule

## What's Next

Currently focusing on:
- Reducing 1-star reviews (most are "didn't match with anyone")
- Improving matching algorithm based on timezone and peak hours
- Adding optional interest-based matching (still completely anonymous)
- Building web version for beta testers
- Analyzing why retention drops after day 1

## Conclusion

Building StrangR taught me that real-time mobile apps are harder than they look. The tech—Socket.io, Firebase, Flutter—is straightforward. The hard part is the details: handling disconnections, managing lifecycle, moderation, performance, and user retention.

But shipping something small and imperfect beats planning something perfect forever.

The app isn't viral. The metrics aren't impressive by startup standards. But real people use it daily, have real conversations, and make real connections.

For a solo developer building in spare time, that is a win.
