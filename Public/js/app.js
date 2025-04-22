//
//  Project: TelegramHarvester
//  Description: A backend system for harvesting and managing public Telegram channel data using TDLib and Vapor.
//  Author: Najy Fannoun
//  Developed By: Najy Fannoun
//  Version: 1.0.0
//  Date: April 2025
//  Copyright: © 2025 Najy Fannoun. All rights reserved.
//
//  License: This project is licensed under the MIT License.
//  You are free to use, modify, and distribute this software under the terms of the MIT License.
//  For more details, please refer to the LICENSE file in the project root directory.
//
//  Disclaimer: This project is intended for educational and research purposes only.
//  The author is not responsible for any misuse or illegal activities that may arise from the use of this software.
//  Please use this software responsibly and in compliance with applicable laws and regulations.
//

const { useState, useEffect } = React;

//  ─── Helper: AllOrigins proxy + HTML‑to‑preview parser ────────────────────
function buildProxyURL(url) {
  return 'https://api.allorigins.win/raw?url=' + encodeURIComponent(url);
}
async function fetchMetadata(url) {
  const res = await fetch(buildProxyURL(url));
  const html = await res.text();
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const getMeta = prop => {
    const el = doc.querySelector(`meta[property="${prop}"]`) ||
               doc.querySelector(`meta[name="${prop}"]`);
    return el?.getAttribute('content') ?? null;
  };
  return {
    title:       getMeta('og:title')       || getMeta('twitter:title')    || 'No title',
    description: getMeta('og:description') || getMeta('twitter:description') || 'No description',
    image:       getMeta('og:image')       || getMeta('twitter:image')     || null,
    url
  };
}
// ─────────────────────────────────────────────────────────────────────────

function App() {
  const [code, setCode]               = useState("");
  const [loggedIn, setLoggedIn]       = useState(false);
  const [messages, setMessages]       = useState([]);
  const [channel, setChannel]         = useState(null);
  const [page, setPage]               = useState(1);
  const [totalPages, setTotalPages]   = useState(1);
  const [loading, setLoading]         = useState(true);
  const [previews, setPreviews]       = useState({});  // url → metadata or null

  // 1️⃣ on mount, check auth
  useEffect(() => { checkAuthStatus() }, []);

  // 2️⃣ whenever messages change, fetch any new previews
  useEffect(() => {
    async function loadPreviews() {
      const upd = { ...previews };
      await Promise.all(messages.map(async msg => {
        const url = msg.mediaUrl;
        if (url && !(url in upd)) {
          try { upd[url] = await fetchMetadata(url) }
          catch { upd[url] = null }
        }
      }));
      setPreviews(upd);
    }
    if (messages.length) loadPreviews();
  }, [messages]);

  async function checkAuthStatus() {
    try {
      const res  = await fetch("/auth/status");
      const json = await res.json();
      if (json.isAuthenticated) {
        setLoggedIn(true);
        await fetchMessages(1);
      }
    } catch(e) {
      console.error("Auth check failed", e);
    } finally {
      setLoading(false);
    }
  }

  async function handleLogin() {
    if (!code) return alert("Enter code");
    try {
      const res = await fetch("/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code })
      });
      if (res.ok) {
        setLoggedIn(true);
        await fetchMessages(1);
        setPage(1);
      } else alert("Invalid code");
    } catch(e) {
      console.error("Login error", e);
      alert("Login failed");
    }
  }

  async function fetchMessages(targetPage) {
    setLoading(true);
    try {
      const res  = await fetch(`/messages?page=${targetPage}`);
      const json = await res.json();
      if (json.messages) {
        setMessages(   json.messages);
        setChannel(    json.channel);
        setTotalPages(json.totalPages || 1);
        setPage(targetPage);
      }
    } catch(e) {
      console.error("Fetch messages failed", e);
    } finally {
      setLoading(false);
    }
  }

  function handlePagination(dir) {
    if (dir === "next" && page < totalPages) fetchMessages(page+1);
    if (dir === "prev" && page > 1)          fetchMessages(page-1);
  }

  return React.createElement("div",{className:"app-container"},[
    // Header
    React.createElement("h1",{className:"header", key:"title"},"🛰️ Telegram Harvester"),

    // Loading / Login / Main view
    loading
      ? React.createElement("p",{className:"loading", key:"loading"},"Loading…")
      : !loggedIn
        ? React.createElement("div",{className:"input-group",key:"login"},[
            React.createElement("input",{
              type:"text", placeholder:"Enter login code",
              value:code, onChange:e=>setCode(e.target.value), key:"in"
            }),
            React.createElement("button",{
              onClick:handleLogin, className:"login-btn", key:"btn"
            },"Login")
          ])
        : [
            // Logged in header
            React.createElement("h2",{className:"status",key:"stat"},"You're logged in 🎉"),
            React.createElement("p",{className:"status-info",key:"page"} ,`Page ${page} of ${totalPages}`),

            // Channel info
            channel && React.createElement("div",{className:"channel-details",key:"chan"},[
              React.createElement("h3",{key:"ct"} ,channel.title),
              channel.photoUrl && React.createElement("img",{
                src:channel.photoUrl, alt:"channel", key:"ci"
              })
            ]),

            // Message grid
            React.createElement("div",{className:"message-grid-container",key:"grid"},[
              React.createElement("div",{className:"message-grid",key:"inner"},[
                messages.map((msg,i)=>React.createElement("div",{className:"message-card",key:i},[
                  // header
                  React.createElement("div",{className:"message-header",key:"h"},[
                    React.createElement("span",{className:"message-id",key:"id"},"#"+msg.messageId),
                    React.createElement("span",{className:"message-date",key:"d"},
                      new Date(msg.date).toLocaleString()
                    )
                  ]),
                  // text
                  React.createElement("p",{className:"message-text",key:"t"},
                    msg.text||"No Text"
                  ),
                  // preview or link
                  msg.mediaUrl && (
                    previews[msg.mediaUrl]
                      ? React.createElement("div",{className:"link-preview",key:"p"},[
                          previews[msg.mediaUrl].image && React.createElement("img",{
                            src:previews[msg.mediaUrl].image,
                            className:"preview-image", key:"pi"
                          }),
                          React.createElement("h4",{className:"preview-title",key:"pt"},
                            previews[msg.mediaUrl].title||"No title"
                          ),
                          React.createElement("p",{className:"preview-desc",key:"pd"},
                            previews[msg.mediaUrl].description||""
                          ),
                          React.createElement("a",{
                            href:msg.mediaUrl,
                            target:"_blank", rel:"noopener noreferrer",
                            className:"preview-link", key:"pl"
                          },"Open ▶︎")
                        ])
                      : React.createElement("a",{
                          href:msg.mediaUrl,
                          target:"_blank", rel:"noopener noreferrer",
                          className:"media-link", key:"ml"
                        },"Open Media")
                  )
                ]))
              ])
            ]),

            // pagination
            React.createElement("div",{className:"pagination",key:"pg"},[
              React.createElement("button",{
                onClick:()=>handlePagination("prev"),
                disabled:page===1, key:"p"
              },"Prev"),
              React.createElement("button",{
                onClick:()=>handlePagination("next"),
                disabled:page===totalPages, key:"n"
              },"Next")
            ])
          ]
  ]);
}

ReactDOM.createRoot(document.getElementById("app"))
  .render(React.createElement(App));
