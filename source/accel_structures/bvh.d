import vector;
import bbox;

import scene;
import ray;

import std.algorithm;
import std.math;
import std.range;
import std.stdio;

struct Bvh(PrimitiveType)
    if(__traits(compiles, PrimitiveType.intersect))
{
	alias NodeId = uint;
	const auto treeArity = 2;
	const auto maxPrimsPerLeaf = 4;

	struct InnerNode {
		BBox3f[treeArity] child_bboxes;
		NodeId[treeArity] child_ids;
	}

	struct LeafNode {
		uint[] prims;
		//PrimitiveType[] prims;
		//uint[maxPrimsPerLeaf] prim_ids;
	}

	struct Node {
		bool is_leaf;
		union {
			InnerNode inner;
			LeafNode leaf;
		}
	}

	Scene!PrimitiveType scene;
	Node[] nodes;
	NodeId root;

	this(Scene!PrimitiveType scene) {
		this.scene = scene;
	}

    pragma(inline, true)
	final @nogc Hit intersect(Ray ray) const {
		immutable bool eager_traversal = true;

		Vec3f inv_ray = Vec3f(1.0) / ray.direction;

		float t;
		Hit hit;
		NodeId[64] stack;

		NodeId nodeid;
		nodeid = root;
		int stack_size = 0;

		//stack[0] = root;
		//int stack_size = 1;
		//while(stack_size > 0) {
		while(true) {
			immutable auto stack_pop =
				"if(stack_size > 0) {
					nodeid = stack[--stack_size];
				} else {
					break;
				}"
			;

			template traverse_node(string node_variable_name) {
				const char[] traverse_node = "
					foreach(prim_id; " ~ node_variable_name ~ ".leaf.prims) {
						if(scene.primitives[prim_id].intersect(ray, t)) {
							if(ray.tmin <= t && t < ray.tmax) {
								hit.primId = cast(int)prim_id;
								hit.t = t;
								ray.tmax = t;
							}
						}
					}";
			}

			//NodeId nodeid = stack[--stack_size];
			const Node* node = &nodes[nodeid];

			if(!eager_traversal && node.is_leaf) {
				mixin(traverse_node!("node"));
				mixin(stack_pop);
			} else {
				if(treeArity == 2) {
					static if(eager_traversal) {
						auto bbox_hit0 = node.inner.child_bboxes[0].intersect(ray, inv_ray);
						bool hit0_valid = bbox_hit0[0] <= bbox_hit0[1] && bbox_hit0[0] < ray.tmax;

						const Node* child0 = &nodes[node.inner.child_ids[0]];
						if(hit0_valid && child0.is_leaf) {
							mixin(traverse_node!("child0"));
							hit0_valid = false;
						}

						auto bbox_hit1 = node.inner.child_bboxes[1].intersect(ray, inv_ray);
						bool hit1_valid = bbox_hit1[0] <= bbox_hit1[1] && bbox_hit1[0] < ray.tmax;
						const Node* child1 = &nodes[node.inner.child_ids[1]];
						if(hit1_valid && child1.is_leaf) {
							mixin(traverse_node!("child1"));
							hit1_valid = false;
						}
					}

					static if(!eager_traversal) {
						auto bbox_hit0 = node.inner.child_bboxes[0].intersect(ray, inv_ray);
						auto bbox_hit1 = node.inner.child_bboxes[1].intersect(ray, inv_ray);

						bool hit0_valid = bbox_hit0[0] <= bbox_hit0[1] && bbox_hit0[0] < ray.tmax;
						bool hit1_valid = bbox_hit1[0] <= bbox_hit1[1] && bbox_hit1[0] < ray.tmax;
					}
					
					if(hit0_valid && hit1_valid) {
						bool hit0_closer = (bbox_hit0[0] < bbox_hit1[0]);
						stack[stack_size++] = node.inner.child_ids[hit0_closer ? 1 : 0];
						//stack[stack_size++] = node.inner.child_ids[hit0_closer ? 0 : 1];
						nodeid = node.inner.child_ids[hit0_closer ? 0 : 1];
					} else if(hit0_valid) {
						//stack[stack_size++] = node.inner.child_ids[0];
						nodeid = node.inner.child_ids[0];
					} else if(hit1_valid) {
						//stack[stack_size++] = node.inner.child_ids[1];
						nodeid = node.inner.child_ids[1];
					} else {
						mixin(stack_pop);
					}
				} else {
					assert(false, "No sorting routine for arity");
					/*foreach(i; 0 .. treeArity) {
						auto bbox_hit = node.inner.child_bboxes[i].intersect(ray, inv_ray);
						if(bbox_hit[0] <= bbox_hit[1] && bbox_hit[0] < ray.tmax) {
							stack[stack_size++] = node.inner.child_ids[i];
						}
					}*/
				}
			}
		}
		return hit;
	}

	static sah_cost_leaf(int nprims, float area) {
		return nprims * area * 5.0;
	}

	static sah_cost_inner(int lprims, float larea, int rprims, float rarea) {
		return larea * lprims * 5.0 + rarea * rprims * 5.0 + 1.0;
	}

	/// Full sweep SAH build
	void build() {
		NodeId build_tree(PrimitiveType[] primitives, uint[] primitives_ids, float area) {
			float leaf_cost = sah_cost_leaf(cast(int)primitives_ids.length, area);
			float best_cost = leaf_cost;
			int best_axis = -1;
			int best_place = -1;

			//writeln(primitives_ids);

			uint[][3] sorted_prims;
			foreach(axis; [0, 1, 2]) {
				alias comparator = (a, b) => std.math.cmp(primitives[a].center.data[axis], primitives[b].center.data[axis]) < 0;
				sorted_prims[axis] = primitives_ids.dup;
				
				sorted_prims[axis].sort!(comparator);
				//static assert(hasSwappableElements!(PrimitiveType[]));
			
				float[] left_area = new float[primitives_ids.length];
				BBox3f bbox = primitives[sorted_prims[axis][0]].center;
				foreach(index, primid; sorted_prims[axis]) {
					left_area[index] = bbox.area();
					bbox = bbox.expand(primitives[primid].bbox());
					//bbox = bbox.expand(prim.bbox());
				}

				bbox = BBox3f(primitives[sorted_prims[axis][primitives_ids.length - 1]].center);
				foreach(index; iota(0, primitives_ids.length).retro) {
					bbox = bbox.expand( primitives[sorted_prims[axis][index]].bbox());
					float right_area = bbox.area();
					//bbox = bbox.expand( sorted_prims[axis][index].bbox());
					float cost = sah_cost_inner(cast(int)index, left_area[index], cast(int)(primitives_ids.length - index), right_area);
					//writeln(index, " ", cost);
					if(cost < best_cost) {
						best_cost = cost;
						best_axis = axis;
						best_place = cast(int)index;
					}
				}
			}

			/*writeln("leaf_cost", leaf_cost);
			writeln("best_axis", best_axis);
			writeln("best_place", best_place);
			writeln("best_cost", best_cost);*/

			if (best_axis == -1) {
				int nodeid = cast(int)nodes.length;
				LeafNode ln = {prims: primitives_ids};
				Node node = { is_leaf: true, leaf: ln };
				nodes ~= node;
				//writeln("wrote leaf node", nodeid, "#prims", ln.prims.length);
				return nodeid;
			} else {
				uint[] left = sorted_prims[best_axis][0 .. best_place];
				uint[] right = sorted_prims[best_axis][best_place .. primitives_ids.length];

				BBox3f left_bbox = primitives[left[0]].center;
				foreach(prim_id; left) {
					//writeln(left_bbox, " + ", primitives[prim_id].bbox(),  " => ", left_bbox.area());
					//writeln(primitives[prim_id]);
					left_bbox = left_bbox.expand(primitives[prim_id].bbox());
				}

				BBox3f right_bbox = primitives[right[0]].center;
				foreach(prim_id; right) {
					right_bbox = right_bbox.expand(primitives[prim_id].bbox());
				}

				/*writeln("left ", left.length, " right ", right.length);
				writeln("left area ", left_bbox.area(), " right area ", right_bbox.area());
				writeln("recomputed cost", sah_cost_inner(cast(int)left.length, left_bbox.area(), cast(int)(right.length), right_bbox.area()));*/

				NodeId left_node = build_tree(primitives, left, left_bbox.area());
				NodeId right_node = build_tree(primitives, right, right_bbox.area());

				int nodeid = cast(int)nodes.length;
				InnerNode inn = {child_bboxes: [left_bbox, right_bbox],
				child_ids: [left_node, right_node]};
				Node node = { is_leaf: false, inner: inn };
				nodes ~= node;
				//writeln("wrote inner node", nodeid);
				return nodeid;
			}
		}

		writeln("Building tree!");

		uint[] prim_ids;
		prim_ids.length = scene.primitives.length;
		BBox3f bbox = BBox3f(scene.primitives[0].center);
		foreach(i; 0 .. scene.primitives.length) {
			prim_ids[i] = cast(int)i;
			bbox = bbox.expand( scene.primitives[i].bbox());
		}

		writeln("Global bbox ", bbox);
		writeln("Global area ", bbox.area());

		root = build_tree(scene.primitives, prim_ids, bbox.area());
		writeln("Built tree.");
	}
}