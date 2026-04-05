# ML & DS - Project Repository (ml_second)

This repository contains two main machine learning and data science projects:
1. **Multi-Agent Web Researcher**
2. **MedHarbor Solution**

Below is the complete architectural and logical explanation for the **Multi-Agent Web Researcher** orchestrator.

---

# Multi-Agent Web Researcher: Architecture & Logic Documentation

This section explains the complete logic, control flow, and library utilization of the **Multi-Agent Web Researcher** project inside the repository. The application orchestrates a robust pipeline of autonomous agents to accept a user query, search the web, scrape the content, strategically synthesize the findings using a Large Language Model (LLM), and output a beautifully formatted Markdown report. 

This happens through two distinct interfaces:
1. **CLI Engine (`main.py`)**: For programmatic and terminal-based research.
2. **Streamlit UI (`app.py`)**: A premium dashboard allowing users to visualize the real-time execution of the agent pipeline, complete with log tracking, scrape status, and report downloading.

---

## 1. The Core Logic: Agent Pipeline

The core logic is modeled sequentially using a 4-step directed approach.

### Step 1: `SearchAgent`
- **Goal**: Find the most relevant URLs for a given topic.
- **Logic**: 
  - Passes the user's research topic to the `Tavily API` via `search_tool.py`.
  - Configured to return a specified maximum number of results (default is 7).
  - Iterates over the raw links and performs a deduplication pass using a `seen_urls` set.
- **Output**: A list of dictionaries containing `title` and `url`.

### Step 2: `ScraperAgent`
- **Goal**: Extract the pure text content from the URLs discovered in Step 1.
- **Logic**:
  - Leverages Python's `ThreadPoolExecutor` to instantiate parallel workers (default is 5).
  - Fetches HTTP web pages concurrently.
  - Extracts the raw HTML and processes it via `BeautifulSoup` (and `lxml`) to strip down script tags, styles, and navigational junk, returning clean text.
  - Skips links that timeout or throw HTTP errors.
- **Output**: A filtered list of successfully scraped pages, structured as `{title, url, content}`.

### Step 3: `SynthesizerAgent` (and Optional FAISS Vector Store)
- **Goal**: Read the raw text from scraped pages and synthesize it into a coherent, factual data structure.
- **FAISS Context Optimization (Optional)**:
  - If enabled (`use_vector_store`), `main.py`/`app.py` processes the scraped text before giving it to the synthesizer. 
  - It breaks the scraped pages into 500-character chunks using LangChain's `RecursiveCharacterTextSplitter`.
  - Embeds the chunks using `GoogleGenerativeAIEmbeddings` and stores them in a `FAISS` in-memory vector database.
  - Performs a similarity search against the user's topic to retrieve only the most relevant text chunks (k=20).
- **Gemini Synthesis**:
  - Aggregates the final text, tracking token counts (`tiktoken` equivalents) to ensure the request strictly fits under the LangChain + Gemini context bounds.
  - Implements a rigid `SYSTEM_PROMPT` giving Gemini the persona of a professional analyst.
  - Instructs Gemini to output **strictly in JSON format**, parsing out keys like `title`, `introduction`, `sections`, `key_insights`, and `conclusion`.
- **Output**: A well-structured Python dictionary.

### Step 4: `FormatterAgent`
- **Goal**: Convert the structured JSON from Step 3 into a clean Markdown document.
- **Logic**: 
  - Stitches together the title, introduction, header sections, lists, and conclusions dynamically.
  - Appends the original `search_results` at the bottom as clickable hyperlinked references.
- **Output**: The polished `.md` string, which gets rendered safely in Streamlit or routed via stdout or to a file from the CLI.

---

## 2. Front-End Logic: Streamlit UI (`app.py`)

The user interface orchestrates the pipeline visually, executing the exact core logic while providing real-time feedback.
- **CSS Styling**: Globally injects modern CSS via `st.markdown`, providing an animated background, glassmorphism UI components, and tailored metric fonts.
- **Pipeline Cards**: Four visual cards (Search, Scrape, Synthesize, Format) map to `pipeline_states`. As the Python code progresses linearly block-by-block, it triggers functions like `refresh_pipeline()` to jump from `"idle"` -> `"active"` -> `"done"`.
- **Simultaneous Action**: As the `ScraperAgent` runs or the LLM processes, `st.empty` slots constantly output colored log files (`render_log()`) and interactive source cards.
- **Exporting**: Utilizes `st.download_button` natively to stream the Markdown buffer straight to the client disk when clicked.

---

## 3. Libraries Used & Their Responsibilities

| Library | Main Purpose | Description of Implementation |
|---|---|---|
| **`streamlit`** | Frontend Web Framework | Drives the entire `app.py` interface. Controls everything from the layout (`st.columns`), dynamic element overwriting (`st.empty`), progress bars, and state management without the need for custom JS or React. |
| **`langchain` / `langchain-core` / `langchain-community`** | AI Orchestration & RAG | Supplies the schema for `SystemMessage` & `HumanMessage`. Powers the VectorStore integrations, Document definitions, and recursive Text Splitters. |
| **`langchain-google-genai` / `google-generateai`** | LLM Engine | The Python SDK targeting `gemini-2.5-flash`. Runs semantic embeddings via `GoogleGenerativeAIEmbeddings` and core synthesis generation via `ChatGoogleGenerativeAI`. |
| **`tavily-python`** | Search Engine | A programmatic web search API tuned for AI. Fetches the initial base of relevant links avoiding direct scraping bans from Google. |
| **`beautifulsoup4` (`bs4`) / `lxml`** | DOM Parsing | Once a webpage is downloaded, BS4 parses the DOM tree so text content can be extracted easily without raw regex. `lxml` handles the backend core parsing engine with C-level parsing speeds. |
| **`requests`** | HTTP Client | Issues `GET` requests within the ThreadPool implementation in the ScraperAgent to pull HTML text from the target IPs. |
| **`faiss-cpu`** | Vector Database | An open-source library constructed by Meta for robust dense vector clustering. Stores the Google semantic embeddings in RAM for extremely fast top-K similarity search processing. |
| **`tiktoken`** | Token Calculus | A fast BPE tokeniser originally by OpenAI. Here, it is utilized as a helper library inside `utils.helpers.count_tokens` to mathematically predict whether prompt sizes fit context budgets before issuing API requests. |
| **`python-dotenv`** | Secrets Management | Hooks into `.env` to programmatically load API keys for Google and Tavily when running the CLI tool seamlessly. |
| **`google-search-results`** | Fallback Module | Provides SerpApi fallback in case Tavily fails traversing results. |

---

## 4. MedHarbor Solution Overview
Also included in this repository is the MedHarbor AI case study files, highlighting practical ML deployment workflows in healthcare architectures.
