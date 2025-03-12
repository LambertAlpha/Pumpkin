import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import Main from "./pages/main";
import User from "./pages/user";
import NaviBar from "./components/ui/navi-bar";

function App() {
  return (    
    <Router>
      <div className="bg-background">
        <NaviBar />
        <Routes>
          <Route path="/" element={<Main />} />
          <Route path="/user" element={<User />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;

