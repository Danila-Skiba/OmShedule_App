import { createBrowserRouter } from "react-router";
import Dashboard from "./screens/Dashboard";
import Schedule from "./screens/Schedule";
import Maps from "./screens/Maps";
import Profile from "./screens/Profile";
import Chat from "./screens/Chat";
import Settings from "./screens/Settings";
import MobileLayout from "./layouts/MobileLayout";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <MobileLayout />,
    children: [
      { index: true, element: <Dashboard /> },
      { path: "schedule", element: <Schedule /> },
      { path: "maps", element: <Maps /> },
      { path: "profile", element: <Profile /> },
      { path: "chat", element: <Chat /> },
      { path: "settings", element: <Settings /> },
    ],
  },
]);