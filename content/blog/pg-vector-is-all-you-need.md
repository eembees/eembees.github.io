+++
title = 'Pg Vector Is All You Need'
date = 2024-01-31T15:43:16+01:00
draft = false
tags = ['tech']
+++

Here at [Corti](http://corti.ai/), we're demoing ways of building a Vector Search product.
I love using Postgres.
How far can I get using Postgres?

The search engine should expose an API that

- [ ] Ingests and embeds arbitrary sentences.
- [ ] Performs nearest neighbor search and outputs the N nearest matches for each query.
- [ ] Passes scalability tests

Using [`pgvector`](https://github.com/pgvector/pgvector) and accompanying [`vecs`](https://pypi.org/project/vecs/) this is rather simple.

I'm using the `pgvector/pgvector:pg16` image for postgres, so enabling the extension becomes a matter of initializing the database like so:

## Dependencies

```sql
CREATE EXTENSION IF NOT EXISTS pg_vector;
```

Then in our `python` API layer we add `vecs` to interact with `pg-vector` and `sentence-transformers` to load language models.  We wrap this in a `fastapi` wrapper deployed with `uvicorn`. For the embedding we're going with the [clip-ViT-B-32](https://huggingface.co/sentence-transformers/clip-ViT-B-32) model for simplicity.

## Writing the API for ingestion and NN search

We can define some base request classes to keep things organized:

```python
class Sentence(BaseModel):
    text: str

class SentenceIngest(Sentence):
    id: str

class SentenceIngestRequest(BaseModel):
    sentences: List[SentenceIngest]

class SentenceRequest(Sentence):
    num: int=3
```

Now we can create our collection:

```python
with vecs.create_client(DB_CONNECTION_STRING) as vx:
    collection = vx.get_or_create_collection(name="clip_vectors", dimension=512, adapter=Adapter(
        [
            TextEmbedding(model='clip-ViT-B-32')
        ]
    ))
```

Writing the ingestion script is extremely simple:

```python
def ingest_collection(sentences:List[Sentence]):

    records =  [ ... ] # transforming sentences to recordx
    
    with vecs.create_client(DB_CONNECTION_STRING) as vx:
        collection = # same as above
        collection.upsert(records) 

@app.put("/sentence")
def sentence_ingest(request:SentenceIngestRequest):
    ingest_collection(request.sentences)

```

And likewise for querying:

```python
def search_collection(sentence:Sentence, num=3)->List[Sentence]:
    with vecs.create_client(DB_CONNECTION_STRING) as vx:
        collection = ... # as earlier

        results = collection.query(
            data=sentence.text,
            limit=num,
            include_metadata=True,
        )
        print(results)

@app.post("/search")
def sentence_retrieve_nearest(request:SentenceRequest):
    return search_collection(request, num=request.num)

```

And that's it!

## Scalability

Scalability testing is next step. I'll return to this when there's time.

## Code link

Code is [here](https://github.com/eembees/pg-vector-testing).
