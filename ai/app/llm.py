import os
import requests

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://ai-ollama-lib-unb-ca:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:3b")

# How much of the model's context window to allocate, in tokens. Worth sizing
# deliberately rather than accepting the default: when a prompt overflows the
# context, it is truncated from the end -- and the question is the last thing
# in the prompt below. The failure mode is a confident answer to a question the
# model never received, with no error anywhere.
#
# The arithmetic for the defaults here: 5 chunks of 800 characters is about
# 1000 tokens, plus source labels, instructions and the question, so roughly
# 1400 in. Adding NUM_PREDICT of output leaves 4096 with comfortable headroom.
# Raise this if the retrieval limit in main.py goes up; on CPU a larger context
# costs memory and speed even when unused.
NUM_CTX = int(os.getenv("OLLAMA_NUM_CTX", "4096"))

# Cap the answer length so one rambling response cannot approach the 120-second
# timeout the Drupal form waits on.
NUM_PREDICT = int(os.getenv("OLLAMA_NUM_PREDICT", "512"))

# Ollama unloads an idle model after five minutes by default, and reloading a
# multi-gigabyte model on CPU makes the next question feel broken. Hold it.
KEEP_ALIVE = os.getenv("OLLAMA_KEEP_ALIVE", "30m")


def cite(chunk: dict) -> str:
    """Label an excerpt the way it should be cited: "Chapter 4, p. 35"."""
    page = chunk.get("printed_page")
    return f"{chunk['title']}, p. {page}" if page else chunk["title"]


def answer_question(question: str, chunks: list[dict]) -> str:
    context = "\n\n".join(
        f"Source: {cite(chunk)} ({chunk['url']})\n{chunk['content']}"
        for chunk in chunks
    )

    # Three instructions here were each added to fix an observed failure, not
    # on principle. A small model reads a grounding rule very literally:
    #
    #  - "the answer is not contained in the context" was read as "not stated
    #    in one sentence", so any question needing two excerpts combined got
    #    refused. Asked how teacher training changed over the century, the
    #    model replied that the excerpts "do not provide a comprehensive
    #    overview" -- while holding passages that answered it. Permission to
    #    combine and summarise is now explicit.
    #  - Chunks are cut at a character count, so most begin and end mid-word.
    #    Saying so stops the model treating a fragment as unusable.
    #  - The refusal must stay available for genuinely unanswerable questions,
    #    so it survives, narrowed to "nothing relevant" rather than "not
    #    stated outright".
    #
    # Loosening a grounding rule risks inviting invention, so the out-of-scope
    # questions are worth re-running after any edit here.
    prompt = f"""
You are a research assistant answering questions about a history of education
in New Brunswick, using excerpts from the book.

Ground every claim in the excerpts below. Do not add outside facts.
The excerpts are fragments and may begin or end mid-sentence; read past that.
You may combine and summarise across several excerpts to answer -- the answer
rarely appears as a single sentence. Only if the excerpts contain nothing
relevant, say: "I could not find that in the education history excerpts
provided."

Answer or decline, never both: do not open with an apology or a disclaimer
about what the excerpts lack and then answer anyway.

Be concise and factual. Cite the excerpts you drew on by chapter and printed
page, exactly as they are labelled above the text, for example
"(Chapter 4, p. 35)". Never invent a page number.

Context:
{context}

Question:
{question}

Answer:
""".strip()

    response = requests.post(
        f"{OLLAMA_BASE_URL}/api/generate",
        json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "keep_alive": KEEP_ALIVE,
            "options": {
                # Temperature controls how much randomness is allowed when
                # picking each next word. The default of 0.8 suits creative
                # writing; here it invites the model to embroider passages it
                # was told to stick to. Zero makes it take the most likely word
                # every time, which also means the same question gives the same
                # answer -- necessary if changes to this pipeline are ever to
                # be compared against each other.
                "temperature": 0,
                "num_ctx": NUM_CTX,
                "num_predict": NUM_PREDICT,
            },
        },
        timeout=120,
    )
    response.raise_for_status()
    data = response.json()
    return data["response"]
