YoldashMoto
Nobody gets left alone on the road. Your bike broke down, you ran out of fuel, you got a flat tire, or you crashed: press one button, and nearby riders, mechanics and tow trucks see that you need help.

Chosen stack: flutter + Supabase. It covers the map, SOS, crash detection, mechanics, tow trucks, the marketplace and role-based registration, and it will be moved to Supabase. Specific technical decisions (architecture, data schema, libraries) are left to the development team. This document describes what the product is, who it is for, and what it must include.

Table of Contents
About the Project
Problem and Solution
Market and Competitors
User Roles
Core Scenarios
Rider App
Mechanic App
Tow Operator App
Motorcycle Marketplace
Admin Panel
Help Request (Order) Lifecycle
Mechanic Matching Logic
Notifications
Ratings and Reviews
Payment, Pricing and Business Model
Safety, Privacy and Trust
Edge Cases
Non-Functional Requirements
Development Stages
Future Ideas
Glossary
1. About the Project
YoldashMoto ("yoldash" is Turkic for "companion, fellow traveler on the road") is a mobile app that brings together the people who can help a motorcyclist in trouble:

other riders nearby: free rider-to-rider help, the community core;
mechanics: both mobile mechanics who come to you and garage mechanics without a storefront;
tow truck operators: for bikes that cannot be fixed on the spot;
automatic crash detection: for when the rider cannot ask for help themselves.
On top of that, the app has a motorcycle marketplace (buy/sell listings with an optional mechanic inspection).

The app grows in three layers:

Community and safety (free, builds the user base): live map, SOS to nearby riders, crash detection.
Services (builds revenue): calling a mechanic, a directory of mechanics and tow trucks.
Marketplace and B2B: bike listings, a dashboard for courier agencies.
Multilingual Support
The app is fully multilingual in three languages: 🇦🇿 Azerbaijani, 🇷🇺 Russian, 🇬🇧 English.

The language is chosen on first launch and can be changed in the profile at any time. By default the device language is used if supported, otherwise Azerbaijani.
The entire interface is translated: all role screens, the admin panel, buttons, errors, hints.
Reference data is translated: problem types, service types, review tags, statuses. When the admin adds a new entry, they fill in all three languages.
Notifications (push, SMS) arrive in the user's chosen language.
User-generated content (comments, reviews, listings, chat) is not machine-translated.
Date, time, number and currency formats (₼ AZN) follow the selected language and region.
2. Problem and Solution
The Problem
A breakdown on the road is stressful and unsafe. It is often unclear who to call, and a motorcycle is hard to move alone.
After a crash the rider may be unconscious and unable to call anyone. In the first half of 2026, 18 people died and 28 were injured in 37 motorcycle and moped accidents in Azerbaijan, which is roughly one death for every two accidents.
Today riders search through friends and WhatsApp groups. That takes time, and there is no certainty about price or quality.
Many good mechanics in Baku work from private garages with no storefront and no map listing, so riders cannot find them and the mechanics cannot find customers.
Tow operators who can carry motorcycles are hard to find.
Buying a used bike is risky because there is no easy way to have it checked.
The Solution
SOS in one tap: every rider within the chosen radius gets a notification and can respond "I'm coming".
Crash detection: the phone detects a hard impact and sends an alert automatically if the rider does not respond.
Call a mechanic: the request goes to nearby online mobile mechanics, one accepts and comes to you.
Directory: garage mechanics and tow operators with services, prices and phone numbers, sorted by distance. The rider calls directly.
Marketplace: bike listings, plus an inspection by an app mechanic before buying.
Value for riders: fast help, often free from other riders; safety after a crash; price transparency. Value for mechanics and tow operators: a flow of customers nearby without opening a shop; the freedom to choose orders. Value for the platform: subscriptions and commissions, demand data, and a community that brings users in for free.

3. Market and Competitors
Starting market: Baku, focusing on couriers first
Over 6,000 couriers work in Baku (Baku Research Institute, 2023). About 38% ride motorcycles and about 15% ride mopeds or scooters, which is roughly 3,000 motorized couriers. They are on the road all day, break down often and carry the highest accident risk.
First-time motorcycle registrations grew about 4x, from 603 in 2022 to 2,687 in 2023, after moped registration and licensing became mandatory on 1 August 2023 (State Statistics Committee).
Only 54 motorcycle service points in Baku are listed on 2GIS. Garage mechanics are not listed at all.
About 1,445 motorcycle and moped listings are on Tap.az. Mopeds are mostly 250–850 ₼, motorcycles 1,600–4,150 ₼.
Go-to-market: partner with 2–3 courier agencies to onboard hundreds of riders at once. This solves the cold-start problem, where an SOS is useless if nobody nearby has the app.

Competitors and references
Product	Country	What it does	Lesson for us
MOTO SOS	Poland / Europe	Rider-to-rider breakdown help, 70 km radius, ~9,000 users	Community help alone grows slowly, so we need a dense starting group
Liberty Rider	France	Crash detection in Premium, €3.99/month, 30,000+ Premium users; 10+ insurers give Premium free to their clients	People and insurers pay for crash detection
EatSleepRIDE	Canada	Crash detection at $49/year, ride tracking, community	Same
Apna Mechanic, BikeFixup	India	Doorstep bike mechanic booking	"Call a mechanic" works as a business on its own
WhatsApp groups, Tap.az, Lalafo	Azerbaijan	Today's alternatives	No radius, no automation, no inspection
No product combines all of these, and none focuses on couriers. There is no local product in Azerbaijan.

4. User Roles
🏍 Rider
Registers, adds motorcycles to "My Garage", sees the live map, sends SOS, calls a mechanic, finds tow trucks, responds to other riders' SOS, and buys or sells bikes.

🔧 Mechanic
Two types, and one person can be both:

Mobile mechanic: goes "online", receives "Call a mechanic" requests and travels to the rider.
Garage mechanic: listed in the directory with services, hours and phone number. Riders call or visit.
Mechanics can add their own services beyond the default list.

🚛 Tow Operator
Creates a page with truck type, service area, price lines (any number, written freely, e.g. "City: 25–35 ₼", "Night rate: 40 ₼"), phone number, hours and an "Available now" toggle. Riders call directly.

🛡 Administrator
A regular account with an is_admin flag. An "Admin Panel" button appears in the profile only for admins. Permission checks are enforced on the server, not just by hiding the button.

One account can switch roles. Mechanics and tow operators ride motorcycles too. Everything entered at registration can be edited later in the profile.

5. Core Scenarios
A. SOS: rider-to-rider help (free, works from day one)
The rider taps SOS and picks the problem type: broken chain, out of fuel, broken cable, flat tire, won't start, dead battery, brake problem, overheating, accident, other.
Optionally adds a comment, a photo, the bike (from My Garage), a landmark and a "can the bike move?" flag.
Every rider within their own chosen radius (2/5/10/25 km) gets a notification.
Anyone who can help taps "I'm coming". The person in trouble sees who is coming. Helpers navigate with Waze or Google Maps.
From the SOS screen the rider can also open nearby mechanics filtered by the problem type, nearby tow trucks, or "Call a mechanic".
The rider closes the SOS when the problem is solved.
B. Automatic crash detection
While riding (speed above ~15 km/h in the last 10 seconds), the accelerometer detects an impact above ~3.5 g.
A full-screen 15-second countdown starts with sound and vibration, plus a large "I'm OK" button.
If the rider does not respond, an automatic "Accident" SOS goes to nearby riders with the location. In Stage 2 it also goes as an SMS with a location link to 2–3 emergency contacts, and support is alerted.
Thresholds are configurable by the admin. Detection can be turned off in the profile.
C. Call a mechanic (paid service)
The rider taps "Call a mechanic", picks the problem, the bike and the location (the marker can be moved, a landmark added).
The request goes to online mobile mechanics nearby (see section 12).
A mechanic accepts. The rider sees their name, photo, rating, vehicle, phone, live movement and ETA.
The mechanic arrives and fixes the problem. The final price is agreed and confirmed in the app. The rider pays and rates.
D. Directory: garage mechanic or tow truck
The rider opens Mechanics or Tow Trucks and filters by service.
Sees distance, services, hours, prices, rating and an "Available now" status.
Calls directly or navigates there. Payment happens between them, outside the app.
E. Marketplace
The rider posts a listing or browses listings. A buyer can order an inspection by an app mechanic before buying (see section 9).

F. Admin
Sees everything on the platform: SOS events, orders, mechanics, tow operators, listings, users, complaints and statistics. Can verify, block and intervene in disputes.

6. Rider App
6.1 Registration and Login
Welcome screen, then Sign up / Log in.
Sign up: choose a role (Rider / Mechanic / Tow operator), fill in the role-specific form, then confirm the phone number with an SMS code.
Minimal rider profile: name, phone, optional photo, riding type (personal / courier / both).
Interface language selection.
Consent to the terms of service and privacy policy.
After registration the app opens on the screen that fits the role.
6.2 My Garage
One or more motorcycles: make, model, year, engine size, color, plate, photo.
The selected bike is attached automatically to SOS, mechanic calls and listings.
6.3 Main Screen: Map (kept minimal)
Full-screen map with the user's location.
On the map: riders (no names until tapped), SOS points, online mobile mechanics, garage mechanics and tow trucks.
Top: a small "N online" chip and at most one alert card (my active SOS, otherwise the nearest SOS).
Bottom: "My location" and a large SOS button. "Call a mechanic" is the second main action.
If nobody is nearby: a clear message plus links to the directory and tow trucks.
6.4 SOS and Call-a-Mechanic Forms
Problem type (multiple allowed; list managed by the admin).
Comment, photo/video (optional), bike from My Garage.
Location: automatic, adjustable, with a landmark field.
"Can the bike move / is towing needed?"
Preliminary call-out price (mechanic call only, if enabled).
6.5 Tracking
SOS: a list of responders ("Kamran is on the way") with their distance; Waze/Google Maps and call buttons; a "Problem solved" button.
Mechanic call: live movement, ETA, mechanic card, call/message, cancel (subject to rules), "Report a problem".
Statuses: "Accepted" → "On the way" → "Arrived" → "In progress".
6.6 Completion
Final report: work done, price, parts used. The rider confirms.
Payment (section 15).
Rating: stars, text and quick tags.
6.7 History
SOS events, mechanic orders and calls made, with re-call options and receipts.

6.8 Profile and Settings
Edit everything from registration: name, phone, bike(s), riding type.
My listings: view, edit and delete own marketplace listings.
SOS notification radius; "show me on the map" (visibility); crash detection on/off; emergency contacts.
Language, notifications, privacy.
Switch role.
Account deletion (required by the App Store).
"Admin Panel" button for admins only.
Log out.
7. Mechanic App
7.1 Registration and Verification
Mechanic type: mobile, garage or both.
Personal data, photo, ID document.
Professional info: specialization (engine, electrical, chain, tires, brakes, carburetor/injector, diagnostics, etc.), plus custom services the mechanic can add and remove later, experience, motorcycle types, tools, vehicle for mobile work.
Garage mechanics: garage name, area, address pin, working hours, note (e.g. "I also come to you").
The application goes to the admin. Until approval, the mechanic is not shown and receives no orders.
Statuses: "Under review", "Approved", "Rejected (with reason)", "Suspended".
7.2 Online Mode (mobile mechanics)
An "Online / Offline" toggle. While online, location is shared and orders arrive.
Maximum radius and accepted problem types.
Automatic offline after a period of inactivity.
7.3 Incoming Order
A card with the problem, description, photos, bike, distance, ETA, approximate price, mini-map and a decision timer, plus "Accept" / "Decline".
A loud sound and vibration that work when the app is minimized.
The mechanic is never obliged to take an order.
7.4 Performing the Order
Route and navigation; call/chat with the rider.
Statuses: "On my way" → "Arrived" → "Started" → "Finished".
Adjust the final price and work list, with rider confirmation.
Escalate: recommend a tow truck from the app directory or a garage.
Cancel with a mandatory reason. Frequent cancellations affect the rating.
7.5 Garage Page (directory)
Public card: name, photo, area, hours, services, rating, reviews, phone, "Available now".
Everything is editable at any time from the profile.
7.6 Earnings (Stage 3)
Order history, commission or subscription status, statistics by day/week/month.

8. Tow Operator App
Registration: name/company, phone, truck type (moto platform, closed van, universal), service area, price lines, hours.
A public page in the Tow Trucks list and on the map.
An "Available now" toggle; unavailable operators are shown as "Busy".
Riders call directly, and payment happens between them outside the app. This is a deliberate product decision.
Everything is editable in the profile: add or remove price lines, change area and hours.
Verification by the admin (truck documents) is recommended before the page goes public.
Later: tow requests as orders, like the mechanic call (Stage 4).
9. Motorcycle Marketplace
Listings: type (motorcycle, moped, scooter, electric), make/model, year, mileage, engine size, price (₼), city, description, color, photos, contact phone.
Search, type filter, sort (newest, cheapest, most expensive), favorites.
VIP listing: shown at the top with a badge (paid; see section 15 for store rules).
"Inspected by a mechanic" badge: the buyer orders an inspection by an app mechanic (engine, chain, brakes, electrical, documents). The mechanic visits the bike, records the result, and the badge appears on the listing.
Own listings are managed from Profile → My listings (edit, delete) and from the listing page itself.
The admin moderates listings (removes fake or prohibited ones).
10. Admin Panel
Access is inside the app through the profile, for is_admin accounts only, with server-side permission checks.

MVP:

Verification queue: mechanic and tow operator applications with documents; approve, reject with a comment, or request changes.
Lists: users, mechanics, tow operators, listings, SOS events, orders. Search and filters.
Blocking: block or unblock users (e.g. for false SOS), suspend mechanics.
Reference data: problem types, service types and review tags, in three languages.
Settings: SOS radius limits, crash detection thresholds, matching parameters.
Stage 2+:

Dashboard: SOS and orders per day, average response and arrival time, cancellations, online mechanics.
Live map of all SOS, orders and online mechanics; a demand heat map.
Order card with the full timeline, GPS track, chat and photos; manual assignment and re-search.
Complaints and disputes.
Review moderation and detection of rating manipulation.
Mass notifications by role or district.
Finance (Stage 3): commissions, subscriptions, payouts, export.
Admin action log; split admin roles (super admin, moderator, support, finance).
11. Help Request (Order) Lifecycle
SOS
Status	Description
Active	Sent; nearby riders notified
Responded	One or more riders tapped "I'm coming"
Resolved	Closed by the sender
Expired	Auto-closed after N hours without resolution
Escalated	The sender called a mechanic or tow truck from the SOS
Mechanic call
Status	Description
Created	The rider placed a call
Searching	Offered to mechanics
No mechanic found	Nobody accepted in time; the rider can retry, widen the radius or use the directory
Accepted	A mechanic accepted
On the way	The rider sees the mechanic moving
Arrived	The mechanic is at the location
In progress	Repair underway
Completed	Awaiting the rider's confirmation and payment
Closed	Done and paid
Cancelled by rider / mechanic / admin	With a reason; a mechanic cancellation restarts the search with priority
Dispute	Needs an admin decision
Every status change is saved with a timestamp and location.

12. Mechanic Matching Logic
MVP: broadcast, first to accept wins.

Find mechanics who are online, within radius, match the problem type, are free and are not blocked.
Send the request to all of them at once.
The first one to accept gets the order (an atomic server-side check). The others see "Already taken".
If nobody accepts within N seconds: widen the radius once, then offer the rider the directory (garage mechanics and tow trucks) and SOS to riders.
Why broadcast first: in the early months there will be few online mechanics. Offering a request to one mechanic at a time would make riders wait too long.

Stage 2+: queue-based matching (Bolt-style), once there are enough mechanics. The order goes to one mechanic at a time, ranked by proximity, rating, acceptance rate and fair distribution. Each mechanic gets 15–30 seconds to respond, and the radius widens automatically. All parameters are configurable in the admin panel.

13. Notifications
Rider: an SOS nearby (within radius); someone is coming to my SOS; a mechanic accepted, is on the way or has arrived; no mechanic found; a reminder to rate; a reply about my listing; support replies. Mechanic: a new order (loud, works when minimized); a cancellation; the verification result; a new review; admin warnings. Tow operator: the verification result; a reminder to update "Available now". Admin: a new application; a new complaint; an SOS or order unanswered for a long time; crash alerts.

Channels: push and in-app. SMS for critical events: crash alerts to emergency contacts, verification codes.

14. Ratings and Reviews
After a mechanic order: the rider rates the mechanic (1–5 stars, text, tags), and the mechanic rates the rider.
Garage mechanics and tow operators can be rated by riders who contacted them. To limit fake reviews, only users with a recorded call or order can rate.
SOS helpers get thanks and "helper points" and badges, which may include a monthly reward for the top helpers.
The rating affects ranking and order priority. Low ratings trigger warnings and then suspension.
Disputed reviews go to admin moderation.
15. Payment, Pricing and Business Model
Principles
Core safety stays free for riders: map, SOS, crash detection, directory.
At launch there are no in-app payments. Mechanic orders are paid in cash, and tow trucks and garage mechanics are paid directly, outside the app.
Tow operator payments never go through the app. This is a product decision.
Revenue streams (in order of launch)
Courier agency dashboard (B2B SaaS): the agency sees its own couriers' live location, SOS and crash alerts, and safety reports. Proposed price: ~2–3 ₼ per courier per month. Sold by contract and invoice.
Mechanic and tow operator subscription: higher ranking, a "Verified" badge, more visibility. Proposed price: ~10–20 ₼/month, starting after ~6 months once they actually get customers. Sold by contract and invoice outside the app.
VIP listings in the marketplace. Proposed price: ~5 ₼ / 7 days.
Mechanic order commission or inspection fee: once card payments are enabled (Stage 3).
Insurance partnerships around crash detection (referral fees). Liberty Rider proves insurers will pay for this.
All prices are proposals to validate with the market.

App Store / Google Play rules (important)
Digital features used inside the app, such as VIP listings or boosting a listing in the same app, must be sold through Apple In-App Purchase / Google Play Billing (Apple guideline 3.1.3(g)), and the stores take a commission.
Real-world services consumed outside the app, such as a mechanic repair, an inspection or towing, must not use In-App Purchase. They are paid in cash or through a regular payment gateway (Apple guideline 3.1.3(e)).
Outside the US, the app may not contain links or buttons that steer users to pay elsewhere for digital features.
B2B subscriptions sold by contract outside the app must not have a "buy" button inside the app.
Payment gateway (when card payments start)
Local options: Epoint (recommended) or Payriff. Typical commission is 1.5–3%. Stripe does not operate directly in Azerbaijan.
Epoint supports individual entrepreneurs, Apple Pay / Google Pay, recurring payments, split payments (automatically splitting a payment between the mechanic and the platform) and 24/7 payouts.
Holding other people's money in an internal balance, then paying it out, may need legal review before launch.
Global "merchant of record" platforms (Paddle, Lemon Squeezy, etc.) accept only pure software subscriptions. They can be used only for the B2B dashboard, not for marketplace or service payments.
Price transparency (mechanic calls)
The rider sees an approximate call-out price before confirming.
The price consists of a call-out fee (distance, time of day), labor, parts and extras (e.g. towing).
The final amount is agreed on the spot and confirmed in the app. A receipt is generated.
Cancellation is free before acceptance. After the mechanic has set off, a call-out fee may apply.
16. Safety, Privacy and Trust
Live map privacy: riders choose whether they are visible. Locations on the public map are approximate. The exact location is shared only in an active SOS (with nearby riders) or an accepted order (with that mechanic), and only for its duration.
Verification of mechanics and tow operators before they are shown.
The rider sees the mechanic's name, photo, rating and vehicle before arrival.
Crash alerts and emergency contacts, plus quick dialing of emergency services (112 / 103).
"Share my trip / SOS" link for family and friends.
Phone numbers hidden in mechanic orders where possible (Stage 2). Directory listings show phone numbers by design.
Abuse protection: limits on false SOS, spam listings and fake reviews.
Strict permission separation: users see only their own data, and admin functions are server-checked.
Personal data protection, plus account and data deletion.
17. Edge Cases
Situation	Expected behavior
Nobody nearby has the app	Show the directory (garage mechanics, tow trucks) and emergency numbers
Nobody answered an SOS	Widen the radius suggestion; offer a mechanic call or a tow truck
No mechanic accepted	Widen the radius once, then offer the directory and SOS
Crash detected but rider is fine	"I'm OK" cancels the countdown; no alert is sent
False crash alert sent	The rider can close it with "False alarm"; responders are notified at once
A mechanic accepted and disappeared	Detect inactivity, offer the rider a re-match, record it in the mechanic's stats
The rider lost internet	The SOS/order is saved; state recovers when the connection returns; phone fallback
Inaccurate GPS	The rider moves the pin and adds a landmark
The rider cancelled after the mechanic set off	The mechanic is notified immediately; compensation rules apply
The mechanic arrived, the rider is gone	Contact, wait, "customer not found" with consequences
Cannot be fixed on the spot	Recommend a tow truck or garage from the directory; price calculated correctly
Two mechanics accept at once	Only the first gets it; the second sees "Already taken"
Mechanic or tow operator forgot to go offline / unavailable	Auto-offline after inactivity; reminder to update "Available now"
Fake or prohibited listing	Report button; admin removes it
Night or bad weather	Possible higher price; the rider is warned about a longer wait
Payment or quality dispute	Complaint → admin review → decision
18. Non-Functional Requirements
Speed: an SOS or order reaches nearby users within seconds. The map updates smoothly.
Reliability: SOS events and orders are never lost on connection failures. State recovers after a restart.
Background operation: mechanics receive orders and share location while the app is minimized. Crash detection works while riding. Battery use stays reasonable.
Platforms: Android and iOS.
Languages: Azerbaijani, Russian and English everywhere, including the admin panel, notifications and reference data. New languages are easy to add.
Simplicity: usable under stress: few actions, large buttons, one-handed use, dark theme (especially at night).
Accessibility: legible fonts, sufficient contrast, system accessibility settings.
Scalability: new cities and countries without reworking the product.
Security: encrypted sensitive data, server-side permissions, admin action log.
Testability: test mode for matching, crash detection and payments.
Observability: error tracking, analytics, service quality metrics.
19. Development Stages
Stage 1: MVP
Registration and login by phone (SMS) with roles: rider, mechanic (mobile/garage), tow operator. Role switching. Everything editable in the profile.
AZ / RU / EN interface.
Rider profile, My Garage (basic).
Live map (minimal main screen, visibility setting).
SOS to nearby riders with "I'm coming", responder list and navigation.
Automatic crash detection with the countdown and an automatic SOS.
Directory: garage mechanics (services incl. custom ones, hours, phone) and tow trucks (price lines, "Available now"), with direct calls.
Call a mechanic: broadcast to online mobile mechanics, first accepts, route, live tracking, statuses, cash payment.
Marketplace: listings, search, filters, My listings (edit/delete), report listing.
Push notifications.
History.
Basic admin panel: verification queue, lists, blocking, reference data, settings.
Account deletion; terms and privacy policy.
Stage 2: Trust and Convenience
Ratings and reviews (both ways); helper points and badges.
Emergency contacts with SMS on crash; "Share my trip / SOS" link.
Photo/video in SOS, orders and listings.
In-app chat/calls; hidden phone numbers in orders.
Complaints and disputes; dashboard, live admin map, demand map.
Queue-based matching settings; background location.
Courier agency dashboard (B2B): first paid product.
Stage 3: Money
Mechanic and tow operator subscriptions.
VIP listings via In-App Purchase / Play Billing.
Card payments for mechanic orders and inspections via a local gateway (e.g. Epoint split payments); commissions; financial reports.
Mechanic inspection orders with the "Inspected" badge.
Promo codes and promotions.
Stage 4: Growth
New cities and countries.
Tow requests as orders (like mechanic calls).
Rider subscription ("Moto care": N free mechanic calls per year, premium crash detection).
Partnerships: insurers, parts stores, service centers, gas stations.
Referral program.
20. Future Ideas
Road hazard map (Waze-style): potholes, oil, sand, roadworks reported by riders.
"Bring fuel": a nearby rider brings fuel for a fee.
Group rides: moto club events, shared routes, convoy mode (calling for help for a whole group).
Scheduled visits (e.g. an oil change at home).
Maintenance reminders based on My Garage data.
Parts marketplace with delivery to the mechanic or rider.
Automatic problem diagnosis from a description and photo.
Moto rental company accounts.
Demand forecasting and hints for mechanics about where to be.
Loyalty program for the best mechanics and helpers.
21. Glossary
Term	Meaning
Rider	A user who rides a motorcycle/moped; may need help or give it
SOS	A help request broadcast to nearby riders (free)
Responder	A rider who tapped "I'm coming" on someone's SOS
Crash detection	Automatic impact detection with a countdown and an auto-SOS
Mobile mechanic	A mechanic who comes to the rider via "Call a mechanic"
Garage mechanic	A mechanic listed in the directory; riders call or visit
Tow operator	A provider with a truck page; paid directly by the rider
Call / Order	A paid request for a mobile mechanic
Directory	The lists of garage mechanics and tow operators
Online	A mobile mechanic's mode for receiving orders
Broadcast matching	An order sent to all nearby online mechanics; the first to accept wins
Queue matching	An order offered to one mechanic at a time (later stage)
Search radius	The maximum distance for SOS notifications or orders
Verification	Admin review of a mechanic or tow operator before going public
My Garage	The list of a user's motorcycles
VIP listing	A paid marketplace listing shown at the top
Inspection	A mechanic's check of a listed bike before purchase
Project Summary
YoldashMoto makes sure no rider is left alone on the road. The free core (live map, SOS to nearby riders, automatic crash detection) builds a community, starting with Baku's ~3,000 motorized couriers. On top of it, riders can call a mobile mechanic, find garage mechanics and tow trucks, and buy or sell bikes with a mechanic inspection. Revenue comes from a courier agency dashboard, mechanic and tow operator subscriptions, VIP listings and, later, commissions on services. Admins manage verification, users, listings, complaints and settings from inside the same app.