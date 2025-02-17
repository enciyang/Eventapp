const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3001;


const USERS_FILE = path.join(__dirname, "users.json");
const EVENTS_FILE = path.join(__dirname, "events.json");
const PARTICIPANTS_FILE = path.join(__dirname, "participants.json");
const NOTIFICATIONS_FILE = path.join(__dirname, "notifications.json");


app.use(cors());
app.use(express.json());


function loadData(filename) {
    try {
        if (fs.existsSync(filename)) {
            return JSON.parse(fs.readFileSync(filename, "utf8"));
        }
        return [];
    } catch (error) {
        console.error(`❌ Error reading ${filename}:`, error);
        return [];
    }
}


function saveData(filename, data) {
    try {
        fs.writeFileSync(filename, JSON.stringify(data, null, 2), "utf8");
        console.log(`✅ Data saved successfully to ${filename}`);
    } catch (error) {
        console.error(`❌ Error saving ${filename}:`, error);
    }
}


app.post("/login", (req, res) => {
    const { username, password } = req.body;
    const users = loadData(USERS_FILE);
    const user = users.find(u => u.username.toLowerCase() === username.toLowerCase() && u.password === password);

    if (user) {
        res.json({ success: true, message: "Login successful", user });
    } else {
        res.status(401).json({ success: false, message: "Invalid username or password" });
    }
});


app.get("/events", (req, res) => {
    res.json(loadData(EVENTS_FILE));
});


app.post("/events", (req, res) => {
    const { title, date, time, venue, description, category, host } = req.body;
    if (!title || !date || !time || !venue || !description || !category || !host) {
        return res.status(400).json({ success: false, message: "All event fields are required" });
    }

    let events = loadData(EVENTS_FILE);
    const newEvent = {
        id: events.length > 0 ? events[events.length - 1].id + 1 : 1,
        title,
        date,
        time,
        venue,
        description,
        category: String(category),
        host,
    };

    events.push(newEvent);
    saveData(EVENTS_FILE, events);
    res.json({ success: true, message: "Event created successfully", event: newEvent });
});


app.put("/events/:eventId", (req, res) => {
    const eventId = parseInt(req.params.eventId);
    let events = loadData(EVENTS_FILE);
    const eventIndex = events.findIndex(e => e.id === eventId);

    if (eventIndex === -1) {
        return res.status(404).json({ success: false, message: "Event not found" });
    }

    const updatedEvent = { ...events[eventIndex], ...req.body };
    events[eventIndex] = updatedEvent;
    saveData(EVENTS_FILE, events);

    let notifications = loadData(NOTIFICATIONS_FILE);
    let participants = loadData(PARTICIPANTS_FILE).filter(p => p.eventId === eventId);

    participants.forEach(participant => {
        notifications.push({
            message: `📢 The event "${updatedEvent.title}" has been updated.`,
            recipient: participant.name,
            timestamp: new Date().toISOString()
        });
    });

    saveData(NOTIFICATIONS_FILE, notifications);
    res.json({ success: true, message: "Event updated successfully", event: updatedEvent });
});


app.delete("/events/:eventId", (req, res) => {
    const eventId = parseInt(req.params.eventId);
    let events = loadData(EVENTS_FILE);
    const eventIndex = events.findIndex(e => e.id === eventId);

    if (eventIndex === -1) {
        return res.status(404).json({ success: false, message: "Event not found" });
    }

    const deletedEvent = events.splice(eventIndex, 1)[0];
    saveData(EVENTS_FILE, events);

    let notifications = loadData(NOTIFICATIONS_FILE);
    let participants = loadData(PARTICIPANTS_FILE).filter(p => p.eventId === eventId);

    participants.forEach(participant => {
        notifications.push({
            message: `🚨 Event deleted: ${deletedEvent.title}`,
            recipient: participant.name,
            timestamp: new Date().toISOString()
        });
    });

    saveData(NOTIFICATIONS_FILE, notifications);

    let participantsData = loadData(PARTICIPANTS_FILE).filter(p => p.eventId !== eventId);
    saveData(PARTICIPANTS_FILE, participantsData);

    res.json({ success: true, message: "Event deleted successfully", deletedEvent });
});


app.post("/join-event", (req, res) => {
    const { username, eventId } = req.body;

    if (!username || !eventId) {
        return res.status(400).json({ success: false, message: "Username and eventId are required" });
    }

    let participants = loadData(PARTICIPANTS_FILE);
    let events = loadData(EVENTS_FILE);

    // Check if event exists
    const eventExists = events.some(event => event.id === parseInt(eventId));
    if (!eventExists) {
        return res.status(404).json({ success: false, message: "Event not found" });
    }


    const alreadyJoined = participants.some(
        p => p.name.toLowerCase() === username.toLowerCase() && p.eventId === parseInt(eventId)
    );

    if (alreadyJoined) {
        return res.status(400).json({ success: false, message: "User already joined this event" });
    }

    // Register user
    participants.push({ name: username, eventId: parseInt(eventId) });
    saveData(PARTICIPANTS_FILE, participants);

    res.json({ success: true, message: "User successfully joined the event" });
});


app.get("/participants/:eventId", (req, res) => {
    const eventId = parseInt(req.params.eventId);
    let participants = loadData(PARTICIPANTS_FILE).filter(p => p.eventId === eventId);

    res.json({ count: participants.length, participants });
});


app.get("/participants/user/:username", (req, res) => {
    const username = req.params.username.trim().toLowerCase();
    const participants = loadData(PARTICIPANTS_FILE);
    const events = loadData(EVENTS_FILE);

    const userEventIds = participants
        .filter(p => p.name.trim().toLowerCase() === username)
        .map(p => parseInt(p.eventId));

    const userEvents = events.filter(event => userEventIds.includes(event.id));

    res.json({ success: true, events: userEvents });
});


app.get("/stats", (req, res) => {
    let events = loadData(EVENTS_FILE);
    let participants = loadData(PARTICIPANTS_FILE);

    let eventParticipation = events.map(event => ({
        id: event.id,
        title: event.title,
        participantCount: participants.filter(p => p.eventId === event.id).length
    }));

    eventParticipation.sort((a, b) => b.participantCount - a.participantCount);
    let mostPopularEvents = eventParticipation.slice(0, 5);

    let categoryCounts = {};
    events.forEach(event => {
        let count = participants.filter(p => p.eventId === event.id).length;
        categoryCounts[event.category] = (categoryCounts[event.category] || 0) + count;
    });

    res.json({ mostPopularEvents, categoryCounts });
});


app.get("/notifications", (req, res) => {
    res.json(loadData(NOTIFICATIONS_FILE));
});


app.listen(PORT, () => {
    console.log(` Server running on http://localhost:${PORT}`);
});

