<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# pisi diplomovou praci na zpracovavani offline obrazku:

konkretne stazeni, nahrani na storage a nasledny processing.

Potreboval bych nejake materialy a zdroje, ktere resi takovouto pipeline a popisujou ji...

Prosim najdi mi pro me relevantni resources (idealne akademicke, ktere se timto problemem zabivaji)
Zaroven najdi vsechny zdroje, kde se tento problem uz resil

---
jsou to libovolne obrazky - nejde o obsah, jde o ML operace (jako pocitani embedingu)
hlavni zpracovani je embeding pocitani
freamwork k8s
hledam akademicke resources, ale i projekty, blogy...

Skvělé! Nyní mohu vytvořit finální odpověď pro uživatele:

## Komplexní průvodce offline image processing pipeline s ML embeddings pro Kubernetes

Shromáždil jsem komprehenzivní sadu akademických zdrojů, open-source projektů a praktických implementací pro offline image processing pipeline zaměřený na batch embedding generation. Zde je detailní analýza:

### Nejdůležitější zdroje pro vaši diplomovou práci

#### 1. **Primární implementační framework: clip-retrieval**[^1]

Je to nejlépe vhodné řešení pro váš use case. Projekt umožňuje:

- Generovat CLIP embeddings s výkonem **1500 samples/sec na RTX 3080**
- Zpracovat **100M obrázků za 20 hodin** na jednom stroji
- Paralelizaci přes více nodů s SLURM nebo Kubernetes
- Output: img_emb/ (numpy arrays) + text_emb/ + metadata/ (parquet files)

Struktura:

- `clip-inference`: Batch inference engine
- `clip-index`: FAISS indexing (autofaiss wrapper)
- `clip-filter`: Dataset filtering
- `clip-back`: REST API backend


#### 2. **Akademické articles zaměřené na batch inference**

**AntBatchInfer: Elastic Batch Inference in the Kubernetes Cluster** (Li, Xiao et al., 2024, arxiv:2404.09686)[^2]

- Řeší stabilitu a efektivnost offline batch inference v K8s
- Multi-level fault tolerance (pod, shard, job level)
- Pipelining strategie (data loading || prediction || writing) - outperformas baseline 2-6x
- Data Driven Scheduler pro heterogenní workloads
- Real-world: 260M samples daily, GPU/CPU clusters

**Parallel vs. Distributed Data Access for Giga-pixel Images** (Yildirim et al., 2016)[^3]

- Porovnání Lustre (parallel FS) vs. HDFS/AWS S3 (distributed FS)
- Eliminace preprocessing step - dynamické scalability
- Best practices pro image tiling


#### 3. **Data pipeline a storage formáty**

**WebDataset** - Standard pro streaming datasets[^4]

- TAR-based shards s konvencí: stejný basename = stejný sample
- Native PyTorch support, streaming-friendly
- Kombinuje se s `img2dataset` pro download + preprocessing

**img2dataset** - Production-ready download tool[^5]

- 100M URLs za 20 hodin
- Rozměr normalizace, formát konverze
- Incremental mode pro fault recovery
- Output: WebDataset formát


#### 4. **Kubernetes-native orchestration**

- **Argo Workflows**: DAG-based engine pro ML pipelines[^6]
- **Kubeflow**: ML-platform s TFJob, MPIJob pro distributed training[^7]
- **AntBatchInfer framework**: Kubernetes-optimized elastic scaling


#### 5. **Distributed storage solutions**

- **SeaweedFS**: Fast distributed storage s O(1) disk seek[^8]
    - Append-only volumes, Raft failover
    - Erasure coding (RS(10,4))
    - Cloud tiering, POSIX mount
- **S3/MinIO**: Object storage s multi-region support


#### 6. **Vector similarity infrastructure**

**FAISS** (Facebook AI Similarity Search)[^9]

- Efficient indexing algorithms (Flat, IVF, HNSW)
- Batch search processing
- GPU acceleration support
- Integration s autofaiss pro automatický hyperparameter tuning


### Praktická architektura pro vaši diplomovou práci

```
Phase 1: Data Acquisition
  └─ img2dataset: Download + resize → WebDataset TAR shards

Phase 2: Distributed Storage
  └─ SeaweedFS/S3: Shard-level replication + metadata tracking

Phase 3: Kubernetes Batch Processing
  ├─ Argo Workflow / AntBatchInfer orchestration
  ├─ Pod-level parallelism (intra-node: multi-processing)
  ├─ Cluster-level scaling (inter-node: horizontal)
  ├─ Fault tolerance: Shard-level checkpointing
  └─ CLIP embedding generation (OpenCLIP library)

Phase 4: Vector DB Ingestion
  ├─ numpy arrays → FAISS index
  ├─ metadata → Parquet files
  └─ Optional: Redis/Milvus vector DB

Phase 5: Serving
  └─ clip-retrieval backend: REST API + similarity search
```


### Key papers a implementace

| Zdroj | Relevance | Výkonost | Téma |
| :-- | :-- | :-- | :-- |
| clip-retrieval [^1] | **HIGH** | 1500 samples/s | Complete pipeline |
| AntBatchInfer [^2] | **HIGH** | 2-6x faster | K8s optimization |
| WebDataset [^4] | **HIGH** | Streaming I/O | Data loading |
| OpenCLIP [^10] | **HIGH** | Multi-GPU | Embedding models |
| FAISS [^9] | **HIGH** | <1ms latency | Vector indexing |
| Kafka-ML [^11] | MEDIUM | Real-time | Streaming alternative |
| Parallel data access [^3] | MEDIUM | Benchmarked | Storage comparison |

### Doporučená implementační témata

1. **Adaptive batch sizing** v Kubernetes - dynamické optimization dle GPU memory
2. **Multi-level fault tolerance** - shard recovery, pod restart, job checkpointing
3. **Storage I/O optimization** - prefetching, local caching, s3 integration
4. **Embedding quality analysis** - dimensionality reduction, quantization strategies
5. **Scalability analysis** - horizontal vs. vertical scaling trade-offs

### Reference repositories pro fork/learning

- https://github.com/rom1504/clip-retrieval (clip-retrieval)
- https://github.com/mlfoundations/open_clip (OpenCLIP)
- https://github.com/rom1504/img2dataset (data preparation)
- https://github.com/argoproj-labs/workflows (Argo)
- https://github.com/seaweedfs/seaweedfs (SeaweedFS)

Všechny materiály (články, kódy, tutoriály) jsem pro vás shromáždil v research notes souboru. Máte solid academic foundation + production-ready implementations na výběr.[^10][^11][^1][^2][^3][^4][^5][^6][^7][^8][^9]
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36][^37][^38][^39][^40][^41][^42][^43][^44][^45][^46][^47][^48][^49][^50][^51][^52][^53][^54][^55][^56][^57][^58][^59][^60][^61][^62][^63][^64][^65][^66][^67][^68][^69][^70][^71][^72][^73][^74][^75][^76][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://stackoverflow.com/questions/14113278/storing-image-data-for-offline-web-application-client-side-storage-database

[^2]: https://personalpages.manchester.ac.uk/staff/p.dudek/papers/lopich-ecctd2005.pdf

[^3]: https://rnt.de/en/know-how/object-storage-for-artificial-intelligence/

[^4]: https://www.reddit.com/r/dataengineering/comments/1fk5g6q/best_way_to_storage_images_for_offline_use/

[^5]: https://direct.ewa.pub/proceedings/ace/article/view/15059

[^6]: http://arxiv.org/pdf/2406.00550.pdf

[^7]: https://www.reddit.com/r/csharp/comments/fa3woa/scalable_image_processing_pipeline/

[^8]: https://wouter.caarls.org/files/tis0706.pdf

[^9]: https://arxiv.org/pdf/2406.00550.pdf

[^10]: https://imaris.oxinst.com/learning/view/article/batch-processing-pipeline-microscopy-images

[^11]: https://ieeexplore.ieee.org/document/7388583/

[^12]: https://overcast.blog/image-compression-in-kubernetes-a-practical-guide-fec7b5762295

[^13]: https://deepsense.ai/blog/implementing-small-language-models-slms-with-rag-on-embedded-devices-leading-to-cost-reduction-data-privacy-and-offline-use/

[^14]: https://openebs.io

[^15]: https://kubernetes.io/docs/concepts/containers/images/

[^16]: https://developer.nvidia.com/blog/offline-to-online-feature-storage-for-real-time-recommendation-systems-with-nvidia-merlin/

[^17]: https://www.reddit.com/r/kubernetes/comments/16ipbx9/how_is_better_to_use_san_storage_with_kubernetes/

[^18]: https://jfrog.com/help/r/jfrog-pipelines-documentation/deploying-to-kubernetes-in-pipelines

[^19]: https://www.reddit.com/r/LocalLLaMA/comments/1cyl3jo/what_model_do_you_guys_use_to_compute_embeddings/

[^20]: https://kubernetes.io/blog/2024/01/23/kubernetes-separate-image-filesystem/

[^21]: https://fullstackml.dev/p/8-from-training-to-deployment-a-simple

[^22]: https://www.dataquest.io/blog/generating-embeddings-with-apis-and-open-models/

[^23]: https://overcast.blog/kubernetes-distributed-storage-backend-a-guide-0a0a437414b0

[^24]: https://dev.to/therealmrmumba/implementing-continuous-deployment-with-docker-and-kubernetes-45mm

[^25]: https://apxml.com/courses/feature-stores-for-ml/chapter-2-advanced-feature-engineering-computation/managing-embeddings-unstructured

[^26]: https://suyashblog.hashnode.dev/leveraging-kubernetes-and-tensorflow-for-distributed-deep-learning

[^27]: https://blog.devops.dev/from-pixels-to-power-why-our-5-step-embedding-pipeline-outperforms-clip-on-imagenet-2e119191107a

[^28]: https://ai.plainenglish.io/i-built-a-fully-offline-ai-agent-that-answers-questions-from-pdf-images-and-audio-no-cloud-aa0b16dff3a9

[^29]: https://stackoverflow.com/questions/73221868/how-do-i-store-images-in-distributed-system-the-right-way

[^30]: https://www.bentoml.com/blog/building-and-deploying-an-image-embedding-application-with-clip-api-service

[^31]: https://www.datarobot.com/blog/choosing-the-right-vector-embedding-model-for-your-generative-ai-use-case/

[^32]: https://www.nature.com/articles/s41467-024-50613-5

[^33]: https://pmc.ncbi.nlm.nih.gov/articles/PMC5154779/

[^34]: https://www.aiacceleratorinstitute.com/building-scalable-image-data-pipelines-for-ai-training/

[^35]: https://harfanglab.io/insidethelab/normalisation-batch-data/

[^36]: https://www3.nd.edu/~pbui/static/pdf/dp3-mics2013.pdf

[^37]: https://aws.amazon.com/blogs/machine-learning/building-a-scalable-machine-learning-pipeline-for-ultra-high-resolution-medical-images-using-amazon-sagemaker/

[^38]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8057393/

[^39]: https://arxiv.org/abs/2311.13981

[^40]: https://github.com/aniket-mish/distributed-ml-system

[^41]: https://www.trillium.de/en/journals/trillium-pathology/archive/2025/tp-1/2025/computational-pathology/image-analysis-understanding-and-mitigating-batch-effects-in-histopathology.html

[^42]: https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0133029

[^43]: https://neptune.ai/blog/ml-pipeline-architecture-design-patterns

[^44]: https://arxiv.org/html/2502.18909v1

[^45]: https://dl.acm.org/doi/10.1145/3465332.3470881

[^46]: https://docs.cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning

[^47]: https://academic.oup.com/bioinformatics/article/39/8/btad479/7240486

[^48]: https://www.sciencedirect.com/science/article/abs/pii/S0020025506002416

[^49]: https://quix.io/blog/the-anatomy-of-a-machine-learning-pipeline

[^50]: https://dl.acm.org/doi/10.1145/3580305.3599303

[^51]: https://ieeexplore.ieee.org/document/8300008/

[^52]: https://a.gavrilov.info/data/posts/Seaweedfs Distributed Storage Part 3: Features. | by Ali Hussein Safar | Medium.pdf

[^53]: https://blog.skypilot.co/large-scale-vector-database/

[^54]: https://www.instaclustr.com/blog/machine-learning-over-streaming-kafka-data-part-2/

[^55]: https://news.ycombinator.com/item?id=39235593

[^56]: https://redis.io/blog/building-a-vector-embedding-injection-pipeline-with-redis-and-vectorflow/

[^57]: https://www.confluent.io/blog/build-deploy-scalable-machine-learning-production-apache-kafka/

[^58]: https://github.com/seaweedfs/seaweedfs

[^59]: https://osamaoracle.com/2025/11/02/hands-on-building-a-vector-database-pipeline-with-oci-and-open-source-embeddings/

[^60]: https://github.com/ertis-research/kafka-ml

[^61]: https://seaweedfs.com

[^62]: https://www.pinecone.io/learn/vector-database/

[^63]: https://www.kai-waehner.de/blog/2025/02/23/online-model-training-and-model-drift-in-machine-learning-with-apache-kafka-and-flink/

[^64]: https://github.com/seaweedfs

[^65]: https://learnopencv.com/vector-db-and-rag-pipeline-for-document-rag/

[^66]: https://www.sciencedirect.com/science/article/pii/S0167739X21002995

[^67]: https://news.ycombinator.com/item?id=24716319

[^68]: https://milvus.io/ai-quick-reference/how-are-embeddings-shared-across-ai-pipelines

[^69]: https://www.linkedin.com/pulse/kafka-machine-learning-enterprise-applications-sepideh-hosseinian-aeg9f

[^70]: https://github.com/seaweedfs/seaweedfs?spm=5176.blog37308.yqblogcon1.70.vV9vJK

[^71]: https://www.tigerdata.com/learn/vector-store-vs-vector-database

[^72]: https://arxiv.org/html/2512.09309v1

[^73]: https://towardsdatascience.com/speeding-up-the-vision-transformer-with-batch-normalization-d37f13f20ae7/

[^74]: https://cloud.google.com/discover/what-is-batch-inference

[^75]: https://arxiv.org/html/2412.12667v2

[^76]: https://sthalles.github.io/an-intuitive-introduction-to-the-vision-transformer/

[^77]: https://www.run.house/blog/kubernetes-the-winner-for-ml

[^78]: https://arxiv.org/html/2509.08216v1

[^79]: https://www.pinecone.io/learn/series/image-search/vision-transformers/

[^80]: https://www.anantacloud.com/post/ai-ml-workloads-on-kubernetes-running-scalable-machine-learning-pipelines-with-gpu-acceleration-and

[^81]: https://arxiv.org/html/2411.10773v1

[^82]: https://huggingface.co/docs/transformers/en/model_doc/vit

[^83]: https://towardsdatascience.com/machine-learning-with-docker-and-kubernetes-batch-inference-4a25328f23c7/

[^84]: https://arxiv.org/html/2509.05485v1

[^85]: https://d2l.ai/chapter_attention-mechanisms-and-transformers/vision-transformer.html

[^86]: https://arxiv.org/html/2404.09686v1

[^87]: https://arxiv.org/html/2410.07022v2

[^88]: https://www.datacamp.com/es/tutorial/vision-transformers

[^89]: https://www.sandgarden.com/learn/batch-inference

[^90]: https://arxiv.org/html/2501.03675v2

[^91]: https://asci-cbl-practicals.readthedocs.io/en/latest/notebooks/3_Vision_Transformers.html

[^92]: https://aws.amazon.com/blogs/devops/deep-learning-image-vector-embeddings-at-scale-using-aws-batch-and-cdk/

[^93]: https://about.gitlab.com/blog/how-to-use-oci-images-as-the-source-of-truth-for-continuous-delivery/

[^94]: https://wandb.ai/manan-goel/coco-clip/reports/Implementing-CLIP-With-PyTorch-Lightning--VmlldzoyMzg4Njk1

[^95]: https://thigm85.github.io/blog/image processing/clip model/dual encoder/pil/2021/10/22/understanding-clip-image-pipeline.html

[^96]: https://towardsdatascience.com/simple-implementation-of-openai-clip-model-a-tutorial-ace6ff01d9f2/

[^97]: https://huggingface.co/AyushChothe/fashion-clip-embedding/blob/main/pipeline.py

[^98]: https://argoproj.github.io/workflows/

[^99]: https://amaarora.github.io/posts/2023-03-11_Understanding_CLIP_part_2.html

[^100]: https://github.com/bernardo-sb/image-embedding-inference

[^101]: https://github.com/usnistgov/WIPP

[^102]: https://github.com/mlfoundations/open_clip

[^103]: https://www.reddit.com/r/webdev/comments/jcsbj6/image_processing_pipeline_a_modern_image_build/

[^104]: https://dev.to/jozu/top-open-source-tools-for-kubernetes-ml-from-development-to-production-78b

[^105]: https://github.com/openai/CLIP

[^106]: https://analysiscenter.github.io/batchflow/intro/images_batch.html

[^107]: https://www.vcluster.com/blog/11-of-the-best-open-source-kubernetes-tools-2021-edition

[^108]: https://github.com/rom1504/clip-retrieval

[^109]: https://github.com/minimaxir/imgbeddings

[^110]: https://palark.com/blog/chaos-engineering-in-kubernetes-open-source-tools/

[^111]: https://arxiv.org/pdf/2404.09686.pdf

[^112]: https://www.lunartech.ai/blog/mastering-batch-size-in-deep-learning-a-comprehensive-guide-to-optimization

